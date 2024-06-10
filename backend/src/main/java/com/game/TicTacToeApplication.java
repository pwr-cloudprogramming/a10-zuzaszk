package com.game;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
// import org.springframework.boot.context.properties.EnableConfigurationProperties;

// import com.game.config.CognitoProperties;

@SpringBootApplication
// @EnableConfigurationProperties(CognitoProperties.class)
public class TicTacToeApplication {

    public static void main(String[] args) {
        SpringApplication.run(TicTacToeApplication.class, args);
    }

}