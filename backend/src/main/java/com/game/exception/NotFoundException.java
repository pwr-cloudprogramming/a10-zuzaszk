package com.game.exception;

public class NotFoundException extends Exception {
    private final String message;

    public NotFoundException(String message) {
        this.message = message;
    }

    public String getMessage() {
        return message;
    }
}