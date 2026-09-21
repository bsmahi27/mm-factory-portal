package com.mmfactory.common.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.method.HandlerTypePredicate;
import org.springframework.web.servlet.config.annotation.ApiVersionConfigurer;
import org.springframework.web.servlet.config.annotation.PathMatchConfigurer;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class ApiVersionConfig implements WebMvcConfigurer {

    @Override
    public void configureApiVersioning(ApiVersionConfigurer configurer) {
        // Tell Spring to look at the URL path to find the version number
        configurer.usePathSegment(1);
    }

    @Override
    public void configurePathMatch(PathMatchConfigurer configurer) {
        // This is the cool part:
        // It dynamically builds the URL structure for you.
        // "v{version}" becomes "v1", "v2", or "v3" automatically.

        configurer.addPathPrefix("/api/v{version}",
                HandlerTypePredicate.forAnnotation(RestController.class)
                        .and(HandlerTypePredicate.forBasePackage("org.springdoc").negate()));
        ;
    }
}