-- This file contains the entities for managing stories in the reminder emails.
-- TURP 2.5 using WordPress to manage Projects and Stories -----------------------------------------------------

-- Projects ---------------------------------

CREATE TABLE "project_revisions" (
	"id" INTEGER NOT NULL DEFAULT,
	"created_at" TIMESTAMP NULL,
	"project_id" INTEGER NOT NULL,
	"title" VARCHAR(255) NOT NULL,
	"content_html" TEXT NOT NULL,
	"contact" VARCHAR(100) NULL DEFAULT NULL,
	"contact_email" VARCHAR(100) NOT NULL,
	"contact_phone" VARCHAR(25) NULL DEFAULT NULL,
	"website_url" VARCHAR(100) NULL DEFAULT NULL,
	"facebook_url" VARCHAR(100) NULL DEFAULT NULL,
	"logo_url" VARCHAR(255) NULL DEFAULT NULL,
	"current_story_id" INTEGER NULL DEFAULT NULL,
	PRIMARY KEY ("id")
)
;

-- Stories ---------------------------------------

CREATE TABLE "story_revisions" (
	"id" INTEGER NOT NULL,
	"created_at" TIMESTAMP NULL,
	"project_id" INTEGER NULL DEFAULT NULL,
	"story_id" INTEGER NOT NULL,
	"story_title" VARCHAR(255) NOT NULL,
	"story_content" VARCHAR(255) NOT NULL,
	"story_url" VARCHAR(255) NULL DEFAULT NULL,
	"story_image_url" VARCHAR(255) NULL DEFAULT NULL,
	"permalink" VARCHAR(150) NULL DEFAULT NULL,
	PRIMARY KEY ("id")
)
;
	
-- View with latest revisions of every Project
CREATE OR REPLACE VIEW latest_project_revisions AS 
SELECT 
	DISTINCT ON (project_id) 
	* 
FROM 
	project_revisions 
ORDER BY 
	project_id, 
	created_at DESC;



-- View with latest revisions of every Story
-- DROP VIEW latest_story_revisions CASCADE;
CREATE OR REPLACE VIEW latest_story_revisions AS 
SELECT 
	DISTINCT ON (story_id) id,
   created_at,
   project_id,
   story_id,
   story_title,
   story_content,
	CASE WHEN story_url IS NULL THEN permalink ELSE story_url END AS story_url,
   story_image_url
FROM story_revisions
ORDER BY 
	story_id, 
	created_at DESC;