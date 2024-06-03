package com.game.exception;

public class InvalidGameException extends Exception {
    private final String message;

    public InvalidGameException(String message) {
        this.message = message;
    }

    public String getMessage() {
        return message;
    }
}