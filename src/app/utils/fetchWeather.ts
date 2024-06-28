import axios from "axios";

export const fetchWeather = async (cityName: string) => {
	const response = await axios.get(`/api/weather?address=${cityName}`);
	return response.data.data;
};
