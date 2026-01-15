package com.casualapp;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

@SpringBootApplication
public class CasualappBackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(CasualappBackendApplication.class, args);
	}

	@Bean
CommandLineRunner printBcrypt() {
  return args -> System.out.println(new BCryptPasswordEncoder().encode("Passw0rd!"));
}
}
