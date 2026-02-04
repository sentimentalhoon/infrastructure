FROM nginx:1.27-alpine

# Install curl for healthcheck
RUN apk add --no-cache curl

# 메인 설정 파일 복사
COPY nginx.conf /etc/nginx/nginx.conf

# 가상 호스트 설정 복사
COPY conf.d/ /etc/nginx/conf.d/

# 커스텀 에러 페이지 복사
COPY html/ /usr/share/nginx/html/

# SSL 디렉토리 생성
RUN mkdir -p /etc/nginx/ssl/campstation /etc/nginx/ssl/psmo

# 로그 디렉토리 권한 설정
RUN mkdir -p /var/log/nginx && \
    chown -R nginx:nginx /var/log/nginx

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
