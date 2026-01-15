
package com.casualapp.security;

import jakarta.validation.constraints.NotBlank;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
public class AuthController {

  private final AuthenticationManager authenticationManager;
  private final JwtService jwtService;

  public AuthController(AuthenticationManager authenticationManager, JwtService jwtService) {
    this.authenticationManager = authenticationManager;
    this.jwtService = jwtService;
  }

  public record LoginRequest(@NotBlank String phoneNumber, @NotBlank String password) {}
  public record LoginResponse(String token) {}

  @PostMapping("/login")
  public LoginResponse login(@RequestBody LoginRequest req) {
    authenticationManager.authenticate(
        new UsernamePasswordAuthenticationToken(req.phoneNumber(), req.password())
    );
    String token = jwtService.generateToken(req.phoneNumber());
    return new LoginResponse(token);
  }
}