import React from "react";
import styles from "../styles/Header.module.css";

interface WeatherFormProps {
	city: string;
	setCity: (city: string) => void;
	fetchData: (cityName: string) => void;
}

const WeatherForm: React.FC<WeatherFormProps> = ({
	city,
	setCity,
	fetchData,
}) => {
	return (
		<form
			className={styles.weatherLocation}
			onSubmit={(e) => {
				e.preventDefault();
				fetchData(city);
			}}
		>
			<input
				className={styles.input_field}
				placeholder="Enter a City"
				type="text"
				id="cityName"
				name="cityName"
				value={city}
				onChange={(e) => setCity(e.target.value)}
			/>
			<button className={styles.search_button} type="submit">
				Search
			</button>
		</form>
	);
};

export default WeatherForm;
