/**
 * Heuristic parser that extracts booking lead fields from raw email text.
 * Handles common phrasings like:
 *   "Guest Name: Barak Obama  Phone: 9876543210  Email: barak@example.com"
 *   "I want to book a room at Beachside Villa from December 20 to December 27, 2025"
 *   ISO dates "2025-12-20" are also supported.
 */

const MONTHS = {
  january: 0, jan: 0, february: 1, feb: 1, march: 2, mar: 2, april: 3, apr: 3,
  may: 4, june: 5, jun: 5, july: 6, jul: 6, august: 7, aug: 7,
  september: 8, sep: 8, sept: 8, october: 9, oct: 9, november: 10, nov: 10,
  december: 11, dec: 11
};

function extractEmail(text) {
  const m = text.match(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/);
  return m ? m[0].toLowerCase() : null;
}

function extractPhone(text) {
  // Prefer an Indian 10-digit number (starts 6-9); fall back to any 10+ digit run.
  const indian = text.match(/\b[6-9]\d{9}\b/);
  if (indian) return indian[0];
  const any = text.match(/\b\d{10,12}\b/);
  return any ? any[0] : null;
}

function extractGuestName(text) {
  // "Guest Name: John Doe" or "Name: John Doe"
  const labeled = text.match(/(?:guest\s*name|name)\s*[:\-]\s*([A-Za-z][A-Za-z .]{1,40}?)(?=\s*(?:phone|email|e-mail|from|\.|,|\n|$))/i);
  if (labeled) return labeled[1].trim().replace(/\s+/g, ' ');
  return null;
}

function extractGuestHouse(text, guestHouses) {
  const lower = text.toLowerCase();
  for (const gh of guestHouses) {
    if (gh.name && lower.includes(gh.name.toLowerCase())) return gh;
  }
  return null;
}

function parseDateToken(token, fallbackYear) {
  token = token.trim();

  // ISO: 2025-12-20
  const iso = token.match(/(\d{4})-(\d{1,2})-(\d{1,2})/);
  if (iso) {
    const d = new Date(Number(iso[1]), Number(iso[2]) - 1, Number(iso[3]));
    return isNaN(d.getTime()) ? null : d;
  }

  // "20 December 2025" / "9 Mar" (day-first) — checked FIRST so a 4-digit
  // year is never mistaken for a day. (?!\d) stops "2026" matching as day "20".
  const dayFirst = token.match(/\b(\d{1,2})(?!\d)\s+([A-Za-z]+)(?:\s*,?\s*(\d{4}))?/);
  // "December 20, 2025" / "December 20" (month-first)
  const monthFirst = token.match(/([A-Za-z]+)\s+(\d{1,2})(?!\d)(?:\s*,?\s*(\d{4}))?/);

  let monthName, day, year;
  if (dayFirst && MONTHS[dayFirst[2].toLowerCase()] !== undefined) {
    day = dayFirst[1];
    monthName = dayFirst[2];
    year = dayFirst[3];
  } else if (monthFirst && MONTHS[monthFirst[1].toLowerCase()] !== undefined) {
    monthName = monthFirst[1];
    day = monthFirst[2];
    year = monthFirst[3];
  } else {
    return null;
  }

  const month = MONTHS[monthName.toLowerCase()];
  if (month === undefined) return null;
  const y = year ? Number(year) : fallbackYear;
  const d = new Date(y, month, Number(day));
  return isNaN(d.getTime()) ? null : d;
}

function extractDates(text) {
  const now = new Date();
  let fallbackYear = now.getFullYear();
  const yearMatch = text.match(/\b(20\d{2})\b/);
  if (yearMatch) fallbackYear = Number(yearMatch[1]);

  // "from <date> to <date>"
  const range = text.match(/from\s+(.+?)\s+(?:to|until|till|-|–)\s+(.+?)(?=[.,\n]|$)/i);
  if (range) {
    const checkIn = parseDateToken(range[1], fallbackYear);
    const checkOut = parseDateToken(range[2], fallbackYear);
    if (checkIn && checkOut) return { checkIn, checkOut };
  }

  // Two ISO dates anywhere
  const isoAll = text.match(/\d{4}-\d{1,2}-\d{1,2}/g);
  if (isoAll && isoAll.length >= 2) {
    const checkIn = parseDateToken(isoAll[0], fallbackYear);
    const checkOut = parseDateToken(isoAll[1], fallbackYear);
    if (checkIn && checkOut) return { checkIn, checkOut };
  }

  return { checkIn: null, checkOut: null };
}

/**
 * @param {string} text   raw email body
 * @param {Array<{_id, name}>} guestHouses  list to match preference against
 * @returns {{ parsed, missing: string[] }}
 */
function parseEmailToLead(text, guestHouses = []) {
  const email = extractEmail(text);
  const phone = extractPhone(text);
  const guestName = extractGuestName(text);
  const gh = extractGuestHouse(text, guestHouses);
  const { checkIn, checkOut } = extractDates(text);

  const parsed = {
    guestName,
    phone,
    email,
    checkIn,
    checkOut,
    preferredGuestHouseId: gh ? gh._id : null,
    preferredGuestHouseName: gh ? gh.name : null
  };

  const missing = [];
  if (!guestName) missing.push('guestName');
  if (!phone) missing.push('phone');
  if (!email) missing.push('email');
  if (!checkIn) missing.push('checkIn');
  if (!checkOut) missing.push('checkOut');

  return { parsed, missing };
}

module.exports = { parseEmailToLead };
