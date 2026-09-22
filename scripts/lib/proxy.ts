export const DEFAULT_PROXY_PORT = "3128";

/** The port the zoo's proxy listens on at localhost, the only way in from the host */
export const PROXY_PORT = Number(process.env.ZOO_PROXY_PORT || DEFAULT_PROXY_PORT);
export const PROXY_URL = `http://localhost:${PROXY_PORT}`;
