import type { Route } from "./+types/home";
import { Welcome } from "../welcome/welcome";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Test" },
    { name: "description", content: "This is antoher foo test" },
  ];
}

export default function Home() {
  return <Welcome />;
}
