export interface Product {
  id: number;
  title: string;
  description: string;
  price: number;
  imageUrl: string;
  category: string;
  rating: { value: number; count: number };
}

export interface ProductSource {
  list(): Promise<Product[]>;
}

export interface ProductLookup {
  get(id: number): Promise<Product>;
}
