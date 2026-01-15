package com.casualapp.security;

import com.casualapp.user.UserEntity;
import com.casualapp.user.UserRepository;
import java.util.List;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.*;
import org.springframework.stereotype.Service;

@Service
public class DbUserDetailsService implements UserDetailsService {

  private final UserRepository userRepository;

  public DbUserDetailsService(UserRepository userRepository) {
    this.userRepository = userRepository;
  }

  @Override
  public UserDetails loadUserByUsername(String phoneNumber) throws UsernameNotFoundException {
    UserEntity user = userRepository.findByPhoneNumber(phoneNumber)
        .orElseThrow(() -> new UsernameNotFoundException("User not found: " + phoneNumber));

    // Spring Security expects roles like "ROLE_ADMIN"
    String role = user.getRole();
    String granted = role.startsWith("ROLE_") ? role : "ROLE_" + role;

    return new org.springframework.security.core.userdetails.User(
        user.getPhoneNumber(),
        user.getPasswordHash(),
        List.of(new SimpleGrantedAuthority(granted))
    );
  }
}