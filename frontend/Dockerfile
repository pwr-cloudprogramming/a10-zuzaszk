# FROM busybox:1.35

# WORKDIR /app

# COPY src/ .

# # ARG ip
# # RUN sed -i "s/localhost/$ip/g" /app/js/socket_js.js
# # RUN sed -i "s/localhost/$ip/g" /app/js/cognito.js

# ENTRYPOINT ["busybox"]

# CMD ["httpd", "-f", "-v", "-p", "3000"]

FROM node:18-alpine

WORKDIR /app

# Copy the package.json and install dependencies
COPY /src/package.json package.json
RUN npm install

# Copy the rest of the application
COPY /src .

# RUN npm run build
EXPOSE 3000
CMD [ "npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "3000"]