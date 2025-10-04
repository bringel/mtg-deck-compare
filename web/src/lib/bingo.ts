function getResponseType(responseType: string) {
  switch (responseType) {
    case 'text':
      return 'text/plain';
    case 'json':
    default:
      return 'application/json';
  }
}

function formatURL(url: string, method: string, parameters: object = {}) {
  if (method === 'GET') {
    const params = new URLSearchParams(Object.entries(parameters));
    const queryString = params.toString();

    return `${url}${queryString ? '?' : ''}${queryString}`;
  } else {
    return url;
  }
}

function request<T>(
  url: string,
  method: string,
  parameters: object,
  responseType: string = 'json'
): Promise<T> {
  const params = {
    method: method,
    body: method !== 'GET' ? JSON.stringify(parameters) : undefined,
    headers: { Accept: getResponseType(responseType) }
  };

  return fetch(formatURL(url, method, parameters), params).then((res) => {
    if (!res.ok) {
      throw new Error(res.statusText);
    }
    if (responseType === 'json') {
      return res.json();
    } else if (responseType === 'text') {
      return res.text();
    }
  });
}

function get<T>(url: string, parameters: object = {}, responseType: string = 'json') {
  return request<T>(url, 'GET', parameters, responseType);
}

function post<T>(url: string, parameters: object = {}, responseType: string = 'json') {
  return request<T>(url, 'POST', parameters, responseType);
}

function put<T>(url: string, parameters: object = {}, responseType: string = 'json') {
  return request<T>(url, 'PUT', parameters, responseType);
}

export default {
  get,
  post,
  put
};
