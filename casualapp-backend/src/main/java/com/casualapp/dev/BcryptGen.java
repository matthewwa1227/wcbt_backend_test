package com.casualapp.dev;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class BcryptGen {
  public static void main(String[] args) {
    String raw = args.length > 0 ? args[0] : "Passw0rd!";
    System.out.println(new BCryptPasswordEncoder().encode(raw));
  }
}