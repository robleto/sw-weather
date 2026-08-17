export interface LocationCandidate {
	name: string;
	regionOrState: string;
	country: string;
	lat: number;
	lon: number;
	displayName: string;
}

export type ParsedLocationQuery =
	| {
			kind: "empty";
	  }
	| {
			kind: "coordinates";
			lat: number;
			lon: number;
			normalizedQuery: string;
	  }
	| {
			kind: "geocode";
			query: string;
			normalizedQuery: string;
	  };
