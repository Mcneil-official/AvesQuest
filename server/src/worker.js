import { BIRD_ID_PROMPT } from './prompt.js';

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return handleCORS();
    }

    if (request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: corsHeaders({ 'Content-Type': 'application/json' }),
      });
    }

    try {
      const { image } = await request.json();
      if (!image) {
        return new Response(JSON.stringify({ error: 'Missing image field' }), {
          status: 400,
          headers: corsHeaders({ 'Content-Type': 'application/json' }),
        });
      }

      const result = await identifyBird(image, env);
      return new Response(JSON.stringify(result), {
        headers: corsHeaders({ 'Content-Type': 'application/json' }),
      });
    } catch (err) {
      return new Response(JSON.stringify({ error: err.message || 'Internal error' }), {
        status: 500,
        headers: corsHeaders({ 'Content-Type': 'application/json' }),
      });
    }
  },
};

async function identifyBird(base64Image, env) {
  const model = '@cf/meta/llama-4-scout-17b-16e-instruct';

  const response = await env.AI.run(model, {
    messages: [
      {
        role: 'user',
        content: [
          { type: 'text', text: BIRD_ID_PROMPT },
          { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${base64Image}` } },
        ],
      },
    ],
    max_tokens: 512,
    temperature: 0.2,
  });

  const rawResponse = response?.response || response?.choices?.[0]?.message?.content || response?.description || '';
  const text = (typeof rawResponse === 'string' ? rawResponse : JSON.stringify(rawResponse)).toString().trim();
  if (!text) {
    return unclearResult(`empty response from model. Response keys: ${Object.keys(response).join(',')}`);
  }

  const trimmed = text.replace(/```json\s*/gi, '').replace(/```\s*$/g, '').trim();

  let parsed;
  try {
    parsed = JSON.parse(trimmed);
  } catch (_) {
    return {
      status: 'unclear',
      common_name: null,
      scientific_name: null,
      confidence: null,
      errorMessage: `Model returned non-JSON response: ${trimmed.substring(0, 500)}`,
    };
  }

  const status = (parsed.status || '').toLowerCase();

  if (status === 'not_a_bird') {
    return {
      status: 'not_a_bird',
      common_name: null,
      scientific_name: null,
      confidence: null,
    };
  }

  if (status === 'unclear') {
    return unclearResult(trimmed);
  }

  const commonName = parsed.common_name?.trim() || null;
  const scientificName = parsed.scientific_name?.trim() || null;

  const confidence = (parsed.confidence != null) ? Number(parsed.confidence) : null;
  const isLowConfidence = (status === 'low_confidence') ||
    (confidence != null && confidence < 0.6);

  if (!commonName && !scientificName) {
    return unclearResult(trimmed);
  }

  return {
    status: isLowConfidence ? 'low_confidence' : 'identified',
    common_name: commonName,
    scientific_name: scientificName,
    confidence: confidence ?? 0.5,
  };
}

function fallbackTextMode(text) {
  const rejectionWords = ['sorry', 'cannot', "can't", 'unable', 'not sure', "don't know", 'no bird', 'not a bird', 'i cannot', 'i am not able', 'unclear', 'could not'];
  const isRejection = rejectionWords.some((w) => text.toLowerCase().includes(w));

  if (isRejection) {
    return unclearResult(text);
  }

  const name = text.replace(/^\s*["']|["']\s*$/g, '').replace(/^It('s| is) (a |an |the )?/i, '').replace(/\.$/, '').trim();

  return {
    status: 'low_confidence',
    common_name: name,
    scientific_name: null,
    confidence: 0.5,
  };
}

function unclearResult(rawText) {
  return {
    status: 'unclear',
    common_name: null,
    scientific_name: null,
    confidence: null,
    errorMessage: rawText ? `Model said: ${rawText.substring(0, 500)}` : 'Model returned unclear result',
  };
}

function corsHeaders(extra = {}) {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    ...extra,
  };
}

function handleCORS() {
  return new Response(null, {
    status: 204,
    headers: corsHeaders(),
  });
}
