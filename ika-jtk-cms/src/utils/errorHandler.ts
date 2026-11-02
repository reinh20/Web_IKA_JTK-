export const getFriendlyErrorMessage = (error: any, defaultMessage: string = 'Terjadi kesalahan sistem.'): string => {
  // Log the actual error to terminal/console for debugging
  console.error('App Error Catch:', error);

  if (!error) return defaultMessage;

  let msg = '';
  
  if (typeof error.response?.data?.error === 'string' && error.response.data.error.trim()) {
    msg = error.response.data.error.trim();
  } else if (typeof error.response?.data?.message === 'string' && error.response.data.message.trim()) {
    msg = error.response.data.message.trim();
  } else if (typeof error.response?.data?.detail === 'string' && error.response.data.detail.trim()) {
    msg = error.response.data.detail.trim();
  } else if (Array.isArray(error.response?.data?.errors) && error.response.data.errors.length > 0) {
    msg = error.response.data.errors.join(', ').trim();
  } else if (typeof error === 'string') {
    msg = error.trim();
  } else if (error.message && typeof error.message === 'string') {
    const lower = error.message.toLowerCase();
    if (!lower.includes('status code') && !lower.includes('request failed') && !lower.includes('network error')) {
      msg = error.message.trim();
    }
  }

  if (!msg) return defaultMessage;

  const lowerMsg = msg.toLowerCase();

  // List of technical jargon and raw HTTP/code keywords that MUST NOT be shown to the user
  const technicalKeywords = [
    'sql', 
    'pdo', 
    'network error', 
    'timeout', 
    'typeerror', 
    'syntaxerror', 
    'internal server error',
    'failed to fetch',
    'econnrefused',
    'status code',
    'axioserror',
    'request failed',
    'bad request',
    'forbidden',
    'unauthorized',
    'err_',
    'exception',
    'uncaught',
    'stack trace',
    'error 500',
    'error 502',
    'error 503',
    'error 504',
    'error 400',
    'error 404',
    'error 401',
    'error 403'
  ];

  for (const keyword of technicalKeywords) {
    if (lowerMsg.includes(keyword)) {
      if (keyword === 'network error' || keyword === 'timeout' || keyword === 'failed to fetch' || keyword === 'econnrefused') {
        return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
      }
      return defaultMessage;
    }
  }

  // If the message is reasonably short and not technical, it is a valid backend business message
  if (msg.length > 0 && msg.length < 250) {
    return msg;
  }

  return defaultMessage;
};
