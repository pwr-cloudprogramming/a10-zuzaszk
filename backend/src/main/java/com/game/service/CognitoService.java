package com.game.service;

import com.amazonaws.services.cognitoidp.AWSCognitoIdentityProvider;
import com.amazonaws.services.cognitoidp.AWSCognitoIdentityProviderClientBuilder;
import com.amazonaws.services.cognitoidp.model.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class CognitoService {

    @Value("${cognito.userPoolId}")
    private String userPoolId;

    @Value("${cognito.clientId}")
    private String clientId;

    private final AWSCognitoIdentityProvider cognitoClient;

    public CognitoService() {
        this.cognitoClient = AWSCognitoIdentityProviderClientBuilder.defaultClient();
    }

    public void registerUser(String email, String password) {
        try {
            SignUpRequest signUpRequest = new SignUpRequest()
                    .withClientId(clientId)
                    .withUsername(email)
                    .withPassword(password)
                    .withUserAttributes(
                            new AttributeType().withName("email").withValue(email)
                    );

            cognitoClient.signUp(signUpRequest);
        } catch (Exception e) {
            throw new RuntimeException("Error registering user: " + e.getMessage(), e);
        }
    }

    public AdminInitiateAuthResult loginUser(String email, String password) {
        try {
            AdminInitiateAuthRequest authRequest = new AdminInitiateAuthRequest()
                    .withUserPoolId(userPoolId)
                    .withClientId(clientId)
                    .withAuthFlow(AuthFlowType.ADMIN_NO_SRP_AUTH)
                    .addAuthParametersEntry("USERNAME", email)
                    .addAuthParametersEntry("PASSWORD", password);

            return cognitoClient.adminInitiateAuth(authRequest);
        } catch (Exception e) {
            throw new RuntimeException("Error logging in user: " + e.getMessage(), e);
        }
    }

    public void confirmUser(String email, String confirmationCode) {
        try {
            ConfirmSignUpRequest confirmRequest = new ConfirmSignUpRequest()
                    .withClientId(clientId)
                    .withUsername(email)
                    .withConfirmationCode(confirmationCode);
    
            cognitoClient.confirmSignUp(confirmRequest);
        } catch (Exception e) {
            throw new RuntimeException("Error confirming user: " + e.getMessage(), e);
        }
    }
}
