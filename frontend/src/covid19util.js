export function areaToStr(a) {
  return `${a.country}${a.state ? " / " + a.state : ""}`;
}

export function strToArea(s) {
  const words = s.split("/");

  return {
    country: words[0].trim(),
    state: words.length === 2 ? words[1].trim() : ""
  };
}
