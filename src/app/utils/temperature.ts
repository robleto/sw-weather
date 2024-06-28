export const convertKelvinToFahrenheit = (kelvin: number): number => {
	return ((kelvin - 273.15) * 9) / 5 + 32;
};
