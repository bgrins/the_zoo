/**
 * Enron email dataset user definitions.
 * These are the top 20 most active/interesting Enron mailboxes.
 * Used by the seed script when ENRON_SEED=true.
 */
export interface EnronUser {
  dirName: string;
  fullName: string;
  emailLocal: string;
  title: string;
}

/** Standard password for all Enron accounts */
export const ENRON_PASSWORD = "EnronZoo.123";

/** Enron mail domain within the zoo */
export const ENRON_DOMAIN = "enron.zoo";

export const enronUsers: EnronUser[] = [
  {
    dirName: "allen-p",
    fullName: "Phillip Allen",
    emailLocal: "phillip.allen",
    title: "Managing Director, Trading",
  },
  {
    dirName: "bass-e",
    fullName: "Eric Bass",
    emailLocal: "eric.bass",
    title: "Trader",
  },
  {
    dirName: "beck-s",
    fullName: "Sally Beck",
    emailLocal: "sally.beck",
    title: "VP, Energy Operations",
  },
  {
    dirName: "blair-l",
    fullName: "Lynn Blair",
    emailLocal: "lynn.blair",
    title: "Director, Pipeline Operations",
  },
  {
    dirName: "campbell-l",
    fullName: "Larry Campbell",
    emailLocal: "larry.campbell",
    title: "VP, Regulatory Affairs",
  },
  {
    dirName: "cash-m",
    fullName: "Michelle Cash",
    emailLocal: "michelle.cash",
    title: "VP & Assistant General Counsel",
  },
  {
    dirName: "dasovich-j",
    fullName: "Jeff Dasovich",
    emailLocal: "jeff.dasovich",
    title: "Government Relations Executive",
  },
  {
    dirName: "davis-d",
    fullName: "Dana Davis",
    emailLocal: "dana.davis",
    title: "Trader",
  },
  {
    dirName: "delainey-d",
    fullName: "David Delainey",
    emailLocal: "david.delainey",
    title: "CEO, Enron Energy Services",
  },
  {
    dirName: "derrick-j",
    fullName: "James Derrick Jr.",
    emailLocal: "james.derrick",
    title: "General Counsel",
  },
  {
    dirName: "farmer-d",
    fullName: "Daren Farmer",
    emailLocal: "daren.farmer",
    title: "Logistics Manager",
  },
  {
    dirName: "germany-c",
    fullName: "Chris Germany",
    emailLocal: "chris.germany",
    title: "Trader, East Power Trading",
  },
  {
    dirName: "griffith-j",
    fullName: "John Griffith",
    emailLocal: "john.griffith",
    title: "VP, Investment Banking",
  },
  {
    dirName: "haedicke-m",
    fullName: "Mark Haedicke",
    emailLocal: "mark.haedicke",
    title: "Managing Director & General Counsel",
  },
  {
    dirName: "kaminski-v",
    fullName: "Vince Kaminski",
    emailLocal: "vince.kaminski",
    title: "Managing Director, Research",
  },
  {
    dirName: "kitchen-l",
    fullName: "Louise Kitchen",
    emailLocal: "louise.kitchen",
    title: "President, Enron Online",
  },
  {
    dirName: "lavorato-j",
    fullName: "John Lavorato",
    emailLocal: "john.lavorato",
    title: "CEO, Enron Americas",
  },
  {
    dirName: "lay-k",
    fullName: "Kenneth Lay",
    emailLocal: "kenneth.lay",
    title: "Chairman & CEO",
  },
  {
    dirName: "shackleton-s",
    fullName: "Sara Shackleton",
    emailLocal: "sara.shackleton",
    title: "VP & Senior Counsel",
  },
  {
    dirName: "skilling-j",
    fullName: "Jeff Skilling",
    emailLocal: "jeff.skilling",
    title: "President & CEO",
  },
];
