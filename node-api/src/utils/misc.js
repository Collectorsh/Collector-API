export const pause = (ms = 300) => new Promise(resolve => setTimeout(resolve, ms));

export const parseError = (e) => {
  if (e instanceof Error) return e.message;
  return e;
}