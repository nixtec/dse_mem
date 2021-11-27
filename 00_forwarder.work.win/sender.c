/*
 * sender.c
 * dse client for testing udp
 */
#include "config.h"
#include "dsecommon.h"

static void dg_cli(int infd, int sockfd, const SA *pservaddr, socklen_t slen);

int main(int argc, char **argv)
{
  int sockfd;
  struct sockaddr_in servaddr;
  short port;

  if (argc < 2) {
    fprintf(stderr, "usage: %s <IPaddress> [port]\n", argv[0]);
    exit(1);
  }

  memset(&servaddr, 0, sizeof(servaddr));
  servaddr.sin_family = AF_INET;
  if (argc > 2) { /* port supplied */
    port = (short) atoi(argv[2]);
  } else {
    port = BINDPORT;
  }
  servaddr.sin_port = htons(port);
  printf("Using port %d\n", port);
#if defined(_WIN32) || defined(__CYGWIN__)
  inet_aton(argv[1], &servaddr.sin_addr);
#else
  inet_pton(AF_INET, argv[1], &servaddr.sin_addr);
#endif

  sockfd = socket(AF_INET, SOCK_DGRAM, 0);
  if (sockfd == -1) {
    perror("socket");
    exit(2);
  }

  dg_cli(0, sockfd, (SA *) &servaddr, sizeof(servaddr));
  close(sockfd);

  return 0;
}

static void dg_cli(int infd, int sockfd, const SA *pservaddr, socklen_t slen)
{
  int n;
  int ret;
  const int on = 1;
  char sendline[MAXLINE];
//  char recvline[MAXLINE+1];

  /* to send to broadcast address, we must set this socket option */
  n = setsockopt(sockfd, SOL_SOCKET, SO_BROADCAST, &on, sizeof(on));
  if (n < 0) {
    perror("setsockopt");
    exit(1);
  }

//  while(fgets(sendline, MAXLINE, fp) != NULL) {
  while((n = read(infd, sendline, MAXLINE)) > 0) {
    ret = sendto(sockfd, sendline, n, 0, pservaddr, slen);
    if (n < 0) {
      perror("sendto");
    }
//    n = recvfrom(sockfd, recvline, MAXLINE, 0, NULL, NULL);

//    recvline[n] = 0; /* null terminate */
//    fputs(recvline, stdout);
  }
}
