package com.mmfactory.common.config;

import io.swagger.v3.oas.models.ExternalDocumentation;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {
    @Bean
    public OpenAPI mmfPortalAPI() {
        return new OpenAPI()
                .info(new Info().title("MM Factory Portal API")
                        .description("Mid-Market Factory Portal covering prospects, campaigns,\n" +
                                "    solutions & assets, triggers radar, Smart Agents, governance, KPIs and\n" +
                                "    administration. Backed by Spring Boot 4 and PostgreSQL; resources map to\n" +
                                "    the tables defined in database/schema.sql.")
                        .version("1.0")
                        .license(new License().name("Apache 2.0").url("http://www.apache.org/licenses/LICENSE-2.0")))
                .externalDocs(new ExternalDocumentation()
                        .description("MM Factory Portal, mahendra-rao.bandaru@capgemini.com")
                        .url("www.capgemini.com"));
    }
}