package com.botai.chatbot;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.io.FileDescriptor;
import java.io.FileOutputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;

@SpringBootApplication
public class ChatbotEngineApplication {

    /**
     * Si ejecutas desde el IDE sin Maven, añade VM options: {@code -Dfile.encoding=UTF-8}
     * (Maven ya lo aplica vía {@code .mvn/jvm.config} y spring-boot-maven-plugin).
     * <p>
     * Fuerza UTF-8 en {@link System#out}/{@link System#err} para que Logback y logs en consola
     * no mezclen bytes UTF-8 con el charset por defecto del proceso en Windows.
     */
    public static void main(String[] args) {
        System.setOut(new PrintStream(new FileOutputStream(FileDescriptor.out), true, StandardCharsets.UTF_8));
        System.setErr(new PrintStream(new FileOutputStream(FileDescriptor.err), true, StandardCharsets.UTF_8));
        SpringApplication.run(ChatbotEngineApplication.class, args);
    }
}
