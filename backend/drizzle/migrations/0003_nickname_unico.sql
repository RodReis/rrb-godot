ALTER TABLE "users" ADD COLUMN "nickname" text;--> statement-breakpoint
CREATE UNIQUE INDEX "users_nickname_lower_idx" ON "users" USING btree (lower("nickname"));