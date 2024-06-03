FROM busybox:1.35

WORKDIR /app

COPY src/ .

ARG ip
RUN sed -i "s/localhost/$ip/g" /app/js/socket_js.js

ENTRYPOINT ["busybox"]

CMD ["httpd", "-f", "-v", "-p", "3000"]