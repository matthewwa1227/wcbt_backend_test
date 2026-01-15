package com.casualapp.user;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "users")
public class UserEntity {

  @Id
  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "phone_number", nullable = false, unique = true)
  private String phoneNumber;

  @Column(name = "password_hash", nullable = false)
  private String passwordHash;

  // DB enum user_role -> store as String for simplicity
  @Column(name = "role", nullable = false)
  private String role;

  // DB enum user_status -> store as String for simplicity
  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "created_at", nullable = false)
  private OffsetDateTime createdAt;

  public UUID getUserId() { return userId; }
  public String getPhoneNumber() { return phoneNumber; }
  public String getPasswordHash() { return passwordHash; }
  public String getRole() { return role; }
  public String getStatus() { return status; }
  public OffsetDateTime getCreatedAt() { return createdAt; }

  public void setUserId(UUID userId) { this.userId = userId; }
  public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
  public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }
  public void setRole(String role) { this.role = role; }
  public void setStatus(String status) { this.status = status; }
  public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
}