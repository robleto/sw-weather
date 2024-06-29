import React, { useState } from "react";
import styles from "../styles/Header.module.css";
import debounce from "lodash.debounce";

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
	const [typingTimeout, setTypingTimeout] = useState<NodeJS.Timeout | null>(
		null
	);

	const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
		const newCity = e.target.value;
		setCity(newCity);

		if (typingTimeout) {
			clearTimeout(typingTimeout);
		}

		const timeout = setTimeout(() => {
			fetchData(newCity);
		}, 500); // Adjust the debounce time as needed

		setTypingTimeout(timeout);
	};

	return (
		<form
			className={styles.weatherLocation}
			onSubmit={(e) => e.preventDefault()}
		>
			<input
				className={styles.input_field}
				placeholder="Enter a City"
				type="text"
				id="cityName"
				name="cityName"
				value={city}
				onChange={handleInputChange}
			/>
		</form>
	);
};

export default WeatherForm;
