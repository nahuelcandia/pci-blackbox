CREATE TABLE CancelRequests (
AuthoriseRequestID uuid not null,
PSPReference text,
Response text not null,
Datestamp timestamptz not null default now(),
PRIMARY KEY (AuthoriseRequestID),
FOREIGN KEY (AuthoriseRequestID) REFERENCES AuthoriseRequests(AuthoriseRequestID)
);
