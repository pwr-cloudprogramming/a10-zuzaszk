package com.game.controller;

import com.amazonaws.services.cognitoidp.model.AdminInitiateAuthResult;
import com.game.service.CognitoService;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@Slf4j
@AllArgsConstructor
public class AuthController {

    private final CognitoService cognitoService;

    @PostMapping("/register")
    public ResponseEntity<String> register(@RequestBody AuthRequest request) {
        try {
            cognitoService.registerUser(request.getEmail(), request.getPassword());
            return ResponseEntity.ok("User registered successfully. Please check your email for verification.");
        } catch (Exception e) {
            log.error("Error registering user: {}", e.getMessage());
            return ResponseEntity.status(500).body("Error registering user: " + e.getMessage());
        }
    }

    @PostMapping("/confirm")
    public ResponseEntity<String> confirm(@RequestBody ConfirmRequest request) {
        try {
            cognitoService.confirmUser(request.getEmail(), request.getConfirmationCode());
            return ResponseEntity.ok("User confirmed successfully.");
        } catch (Exception e) {
            log.error("Error confirming user: {}", e.getMessage());
            return ResponseEntity.status(500).body("Error confirming user: " + e.getMessage());
        }
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody AuthRequest request) {
        try {
            AdminInitiateAuthResult authResult = cognitoService.loginUser(request.getEmail(), request.getPassword());
            String idToken = authResult.getAuthenticationResult().getIdToken();
            return ResponseEntity.ok(new AuthResponse(idToken));
        } catch (Exception e) {
            log.error("Error logging in user: {}", e.getMessage());
            return ResponseEntity.status(500).body(new AuthResponse("Error logging in user: " + e.getMessage()));
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout(@RequestBody LogoutRequest request) {
        try {
            cognitoService.logoutUser(request.getAccessToken());
            return ResponseEntity.ok("User logged out successfully.");
        } catch (Exception e) {
            log.error("Error logging out user: {}", e.getMessage());
            return ResponseEntity.status(500).body("Error logging out user: " + e.getMessage());
        }
    }

    @PostMapping("/refresh-token")
    public ResponseEntity<?> refreshToken(@RequestBody RefreshTokenRequest request) {
        try {
            AdminInitiateAuthResult authResult = cognitoService.refreshToken(request.getRefreshToken());
            return ResponseEntity.ok(authResult);
        } catch (Exception e) {
            log.error("Error refreshing token: {}", e.getMessage());
            return ResponseEntity.status(500).body("Error refreshing token: " + e.getMessage());
        }
    }

    

}

@Data
class AuthRequest {
    private String email;
    private String password;
}

@Data
class ConfirmRequest {
    private String email;
    private String confirmationCode;
}

@Data
@AllArgsConstructor
class AuthResponse {
    private String idToken;
}

@Data
class LogoutRequest {
    private String accessToken;
}

@Data
class RefreshTokenRequest {
    private String refreshToken;
}
