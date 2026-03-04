import {
  ShoppingCart, Utensils, Car, Lightbulb, Film, Heart,
  ShoppingBag, DollarSign, HelpCircle, Tag, Home, Briefcase,
  Plane, GraduationCap, Gift, Music, Wifi, Phone, CreditCard,
  TrendingUp, Wallet, PiggyBank, Building2, Zap, Droplets,
  Fuel, Bus, Train, Bike, Ship, Coffee, Pizza, Apple,
  Shirt, Watch, Gem, Scissors, Dumbbell, Stethoscope,
  Pill, Baby, Dog, Cat, TreePine, Flower2, Hammer,
  Wrench, Paintbrush, Camera, Tv, Gamepad2, BookOpen,
  Newspaper, Globe, Map, Compass, Umbrella, Sun, Moon,
  CloudRain, Snowflake, Flame, type LucideIcon,
} from 'lucide-react';

export const ICON_MAP: Record<string, LucideIcon> = {
  ShoppingCart,
  Utensils,
  Car,
  Lightbulb,
  Film,
  Heart,
  ShoppingBag,
  DollarSign,
  HelpCircle,
  Tag,
  Home,
  Briefcase,
  Plane,
  GraduationCap,
  Gift,
  Music,
  Wifi,
  Phone,
  CreditCard,
  TrendingUp,
  Wallet,
  PiggyBank,
  Building2,
  Zap,
  Droplets,
  Fuel,
  Bus,
  Train,
  Bike,
  Ship,
  Coffee,
  Pizza,
  Apple,
  Shirt,
  Watch,
  Gem,
  Scissors,
  Dumbbell,
  Stethoscope,
  Pill,
  Baby,
  Dog,
  Cat,
  TreePine,
  Flower2,
  Hammer,
  Wrench,
  Paintbrush,
  Camera,
  Tv,
  Gamepad2,
  BookOpen,
  Newspaper,
  Globe,
  Map,
  Compass,
  Umbrella,
  Sun,
  Moon,
  CloudRain,
  Snowflake,
  Flame,
};

export const ICON_NAMES = Object.keys(ICON_MAP);

// Build a case-insensitive lookup for resilient icon matching
const ICON_MAP_LOWER: Record<string, LucideIcon> = {};
for (const [key, icon] of Object.entries(ICON_MAP)) {
  ICON_MAP_LOWER[key.toLowerCase()] = icon;
}

export function getIcon(name: string | undefined | null): LucideIcon {
  if (!name || typeof name !== 'string') return HelpCircle;

  // Exact match first
  if (ICON_MAP[name]) return ICON_MAP[name];

  // Case-insensitive match
  const lower = name.toLowerCase();
  if (ICON_MAP_LOWER[lower]) return ICON_MAP_LOWER[lower];

  // Handle snake_case / kebab-case names (e.g. "shopping_cart" -> "ShoppingCart")
  const pascal = name
    .replace(/[-_](.)/g, (_, c: string) => c.toUpperCase())
    .replace(/^(.)/, (_, c: string) => c.toUpperCase());
  if (ICON_MAP[pascal]) return ICON_MAP[pascal];

  return HelpCircle;
}
