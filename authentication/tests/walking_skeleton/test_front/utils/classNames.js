import { clsx } from "clsx";
import { twMerge } from "tailwind-merge";

//Class to use for className manipulation in React components.
export default function classNames(...classes) {
    return classes.filter(Boolean).join(" ");
}

export function cn(...inputs) {
    return twMerge(clsx(inputs))
}
