export const parseError = (e) => { 
  if (e instanceof Error) return e.message;
  return e;
}