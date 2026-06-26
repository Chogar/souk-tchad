import {
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private client: GoogleGenerativeAI | null = null;
  private requestTimestamps: number[] = [];

  constructor(private readonly configService: ConfigService) {
    const apiKey = this.configService.get<string>('gemini.apiKey');
    if (apiKey) {
      this.client = new GoogleGenerativeAI(apiKey);
    }
  }

  private getModel(
    modelOverride?: string,
    options?: { jsonResponse?: boolean },
  ) {
    if (!this.client) {
      throw new HttpException(
        'Recherche par image indisponible — clé Gemini non configurée',
        HttpStatus.SERVICE_UNAVAILABLE,
      );
    }
    const modelName =
      modelOverride ??
      this.configService.get<string>('gemini.model') ??
      'gemini-2.5-flash';
    return this.client.getGenerativeModel({
      model: modelName,
      ...(options?.jsonResponse
        ? {
            generationConfig: {
              responseMimeType: 'application/json',
              temperature: 0.2,
            },
          }
        : {}),
    });
  }

  private parseJsonResponse<T>(text: string): T | null {
    const trimmed = text.trim();
    try {
      return JSON.parse(trimmed) as T;
    } catch {
      const fenced = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
      if (fenced?.[1]) {
        try {
          return JSON.parse(fenced[1].trim()) as T;
        } catch {
          return null;
        }
      }
      const start = trimmed.indexOf('{');
      const end = trimmed.lastIndexOf('}');
      if (start >= 0 && end > start) {
        try {
          return JSON.parse(trimmed.slice(start, end + 1)) as T;
        } catch {
          return null;
        }
      }
      return null;
    }
  }

  private checkQuota(): void {
    const rpmLimit = this.configService.get<number>('gemini.rpmLimit') ?? 15;
    const now = Date.now();
    this.requestTimestamps = this.requestTimestamps.filter(
      (t) => now - t < 60_000,
    );

    if (this.requestTimestamps.length >= rpmLimit) {
      throw new HttpException(
        'Quota Gemini gratuit atteint — réessayez dans une minute',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
    this.requestTimestamps.push(now);
  }

  async translate(text: string, targetLang = 'fr'): Promise<string> {
    if (!this.client) {
      this.logger.warn('Gemini non configuré — texte original retourné');
      return text;
    }

    this.checkQuota();
    const result = await this.getModel().generateContent(
      `Traduis ce texte en ${targetLang}, retourne uniquement la traduction :\n${text}`,
    );
    return result.response.text().trim();
  }

  async improveListing(title: string, description: string): Promise<{
    title: string;
    description: string;
  }> {
    if (!this.client) {
      return { title, description };
    }

    this.checkQuota();
    const result = await this.getModel().generateContent(
      `Améliore cette annonce de marketplace au Tchad. Retourne un JSON avec "title" et "description" uniquement.\nTitre: ${title}\nDescription: ${description}`,
    );

    try {
      const text = result.response.text().trim();
      const json = JSON.parse(text.replace(/```json|```/g, '').trim()) as {
        title: string;
        description: string;
      };
      return json;
    } catch {
      return { title, description };
    }
  }

  private normalizeMimeType(mimeType: string): string {
    const lower = mimeType.toLowerCase();
    if (lower.includes('png')) return 'image/png';
    if (lower.includes('webp')) return 'image/webp';
    return 'image/jpeg';
  }

  private extractSearchResult(text: string): {
    keywords: string;
    primaryTerm: string | null;
    categoryHint: string | null;
  } {
    const json = this.parseJsonResponse<{
      keywords?: string;
      primaryTerm?: string | null;
      categoryHint?: string | null;
    }>(text);

    if (json?.keywords?.trim()) {
      return {
        keywords: json.keywords.trim(),
        primaryTerm: json.primaryTerm?.trim() || null,
        categoryHint:
          json.categoryHint?.trim() === 'null'
            ? null
            : json.categoryHint?.trim() || null,
      };
    }

    const keywordsMatch = text.match(/"keywords"\s*:\s*"([^"]+)"/i);
    if (keywordsMatch?.[1]?.trim()) {
      const primaryMatch = text.match(/"primaryTerm"\s*:\s*"([^"]+)"/i);
      const categoryMatch = text.match(/"categoryHint"\s*:\s*"([^"]+)"/i);
      return {
        keywords: keywordsMatch[1].trim(),
        primaryTerm: primaryMatch?.[1]?.trim() || null,
        categoryHint:
          categoryMatch?.[1]?.trim() === 'null'
            ? null
            : categoryMatch?.[1]?.trim() || null,
      };
    }

    throw new Error('JSON invalide');
  }

  private async analyzeImageWithModel(
    buffer: Buffer,
    mimeType: string,
    modelName: string,
  ): Promise<{
    keywords: string;
    primaryTerm: string | null;
    categoryHint: string | null;
  }> {
    const result = await this.getModel(modelName, {
      jsonResponse: true,
    }).generateContent([
      {
        inlineData: {
          data: buffer.toString('base64'),
          mimeType: this.normalizeMimeType(mimeType),
        },
      },
      {
        text: `Tu analyses une photo pour une marketplace au Tchad.
Retourne UNIQUEMENT ce JSON (pas de texte autour):
{"keywords":"3-6 mots descriptifs en français","primaryTerm":"objet principal ou marque","categoryHint":"automobiles|immobilier|electronique|emplois|services|meubles|mode|animaux|null"}`,
      },
    ]);

    const feedback = result.response.promptFeedback;
    if (feedback?.blockReason) {
      throw new Error(`Contenu bloqué: ${feedback.blockReason}`);
    }

    const text = result.response.text()?.trim();
    if (!text) {
      throw new Error('Réponse IA vide');
    }

    return this.extractSearchResult(text);
  }

  async searchByImage(
    buffer: Buffer,
    mimeType: string,
  ): Promise<{
    keywords: string;
    primaryTerm: string | null;
    categoryHint: string | null;
  }> {
    this.checkQuota();

    const configuredModel =
      this.configService.get<string>('gemini.visionModel') ??
      'gemini-2.5-flash';
    const modelsToTry = [
      configuredModel,
      'gemini-2.5-flash',
      'gemini-2.0-flash',
    ].filter((model, index, all) => all.indexOf(model) === index);

    let lastError: unknown = null;
    for (const modelName of modelsToTry) {
      try {
        return await this.analyzeImageWithModel(buffer, mimeType, modelName);
      } catch (error) {
        lastError = error;
        this.logger.warn(`Analyse image (${modelName}) échouée: ${error}`);
      }
    }

    const detail =
      lastError instanceof Error ? lastError.message : String(lastError);
    const isAuthError =
      detail.toLowerCase().includes('api key') ||
      detail.toLowerCase().includes('api_key_invalid') ||
      detail.toLowerCase().includes('permission');

    throw new HttpException(
      isAuthError
        ? 'Clé Gemini invalide — vérifiez GEMINI_API_KEY dans le fichier .env'
        : `Impossible d'analyser l'image — ${detail}`,
      isAuthError ? HttpStatus.SERVICE_UNAVAILABLE : HttpStatus.UNPROCESSABLE_ENTITY,
    );
  }
}
