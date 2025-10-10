--
-- PostgreSQL database dump
--

\restrict SMMJbywCVsqbysM8AsgU3HpnrxbSx6SoZOp4yuSA7vDXj5qSCXww5nI8e6ciyaC

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: access; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.access (
    id bigint NOT NULL,
    user_id bigint,
    repo_id bigint,
    mode integer
);


ALTER TABLE public.access OWNER TO gitea_user;

--
-- Name: access_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.access_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.access_id_seq OWNER TO gitea_user;

--
-- Name: access_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.access_id_seq OWNED BY public.access.id;


--
-- Name: access_token; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.access_token (
    id bigint NOT NULL,
    uid bigint,
    name character varying(255),
    token_hash character varying(255),
    token_salt character varying(255),
    token_last_eight character varying(255),
    scope character varying(255),
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.access_token OWNER TO gitea_user;

--
-- Name: access_token_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.access_token_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.access_token_id_seq OWNER TO gitea_user;

--
-- Name: access_token_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.access_token_id_seq OWNED BY public.access_token.id;


--
-- Name: action; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.action (
    id bigint NOT NULL,
    user_id bigint,
    op_type integer,
    act_user_id bigint,
    repo_id bigint,
    comment_id bigint,
    is_deleted boolean DEFAULT false NOT NULL,
    ref_name character varying(255),
    is_private boolean DEFAULT false NOT NULL,
    content text,
    created_unix bigint
);


ALTER TABLE public.action OWNER TO gitea_user;

--
-- Name: action_artifact; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.action_artifact (
    id bigint NOT NULL,
    run_id bigint,
    runner_id bigint,
    repo_id bigint,
    owner_id bigint,
    commit_sha character varying(255),
    storage_path character varying(255),
    file_size bigint,
    file_compressed_size bigint,
    content_encoding character varying(255),
    artifact_path character varying(255),
    artifact_name character varying(255),
    status bigint,
    created_unix bigint,
    updated_unix bigint,
    expired_unix bigint
);


ALTER TABLE public.action_artifact OWNER TO gitea_user;

--
-- Name: action_artifact_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.action_artifact_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.action_artifact_id_seq OWNER TO gitea_user;

--
-- Name: action_artifact_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.action_artifact_id_seq OWNED BY public.action_artifact.id;


--
-- Name: action_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.action_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.action_id_seq OWNER TO gitea_user;

--
-- Name: action_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.action_id_seq OWNED BY public.action.id;


--
-- Name: action_run; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.action_run (
    id bigint NOT NULL,
    title character varying(255),
    repo_id bigint,
    owner_id bigint,
    workflow_id character varying(255),
    index bigint,
    trigger_user_id bigint,
    schedule_id bigint,
    ref character varying(255),
    commit_sha character varying(255),
    is_fork_pull_request boolean,
    need_approval boolean,
    approved_by bigint,
    event character varying(255),
    event_payload text,
    trigger_event character varying(255),
    status integer,
    version integer DEFAULT 0,
    started bigint,
    stopped bigint,
    previous_duration bigint,
    created bigint,
    updated bigint
);


ALTER TABLE public.action_run OWNER TO gitea_user;

--
-- Name: action_run_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.action_run_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.action_run_id_seq OWNER TO gitea_user;

--
-- Name: action_run_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.action_run_id_seq OWNED BY public.action_run.id;


--
-- Name: action_run_index; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.action_run_index (
    group_id bigint NOT NULL,
    max_index bigint
);


ALTER TABLE public.action_run_index OWNER TO gitea_user;

--
-- Name: action_run_job; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.action_run_job (
    id bigint NOT NULL,
    run_id bigint,
    repo_id bigint,
    owner_id bigint,
    commit_sha character varying(255),
    is_fork_pull_request boolean,
    name character varying(255),
    attempt bigint,
    workflow_payload bytea,
    job_id character varying(255),
    needs text,
    runs_on text,
    task_id bigint,
    status integer,
    started bigint,
    stopped bigint,
    created bigint,
    updated bigint
);


ALTER TABLE public.action_run_job OWNER TO gitea_user;

--
-- Name: action_run_job_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.action_run_job_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.action_run_job_id_seq OWNER TO gitea_user;

--
-- Name: action_run_job_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.action_run_job_id_seq OWNED BY public.action_run_job.id;


--
-- Name: action_runner; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.action_runner (
    id bigint NOT NULL,
    uuid character(36),
    name character varying(255),
    version character varying(64),
    owner_id bigint,
    repo_id bigint,
    description text,
    base integer,
    repo_range character varying(255),
    token_hash character varying(255),
    token_salt character varying(255),
    last_online bigint,
    last_active bigint,
    agent_labels text,
    ephemeral boolean DEFAULT false NOT NULL,
    created bigint,
    updated bigint,
    deleted bigint
);


ALTER TABLE public.action_runner OWNER TO gitea_user;

--
-- Name: action_runner_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.action_runner_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.action_runner_id_seq OWNER TO gitea_user;

--
-- Name: action_runner_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.action_runner_id_seq OWNED BY public.action_runner.id;


--
-- Name: action_runner_token; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.action_runner_token (
    id bigint NOT NULL,
    token character varying(255),
    owner_id bigint,
    repo_id bigint,
    is_active boolean,
    created bigint,
    updated bigint,
    deleted bigint
);


ALTER TABLE public.action_runner_token OWNER TO gitea_user;

--
-- Name: action_runner_token_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.action_runner_token_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.action_runner_token_id_seq OWNER TO gitea_user;

--
-- Name: action_runner_token_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.action_runner_token_id_seq OWNED BY public.action_runner_token.id;


--
-- Name: action_schedule; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.action_schedule (
    id bigint NOT NULL,
    title character varying(255),
    specs text,
    repo_id bigint,
    owner_id bigint,
    workflow_id character varying(255),
    trigger_user_id bigint,
    ref character varying(255),
    commit_sha character varying(255),
    event character varying(255),
    event_payload text,
    content bytea,
    created bigint,
    updated bigint
);


ALTER TABLE public.action_schedule OWNER TO gitea_user;

--
-- Name: action_schedule_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.action_schedule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.action_schedule_id_seq OWNER TO gitea_user;

--
-- Name: action_schedule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.action_schedule_id_seq OWNED BY public.action_schedule.id;


--
-- Name: action_schedule_spec; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.action_schedule_spec (
    id bigint NOT NULL,
    repo_id bigint,
    schedule_id bigint,
    next bigint,
    prev bigint,
    spec character varying(255),
    created bigint,
    updated bigint
);


ALTER TABLE public.action_schedule_spec OWNER TO gitea_user;

--
-- Name: action_schedule_spec_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.action_schedule_spec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.action_schedule_spec_id_seq OWNER TO gitea_user;

--
-- Name: action_schedule_spec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.action_schedule_spec_id_seq OWNED BY public.action_schedule_spec.id;


--
-- Name: action_task; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.action_task (
    id bigint NOT NULL,
    job_id bigint,
    attempt bigint,
    runner_id bigint,
    status integer,
    started bigint,
    stopped bigint,
    repo_id bigint,
    owner_id bigint,
    commit_sha character varying(255),
    is_fork_pull_request boolean,
    token_hash character varying(255),
    token_salt character varying(255),
    token_last_eight character varying(255),
    log_filename character varying(255),
    log_in_storage boolean,
    log_length bigint,
    log_size bigint,
    log_indexes bytea,
    log_expired boolean,
    created bigint,
    updated bigint
);


ALTER TABLE public.action_task OWNER TO gitea_user;

--
-- Name: action_task_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.action_task_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.action_task_id_seq OWNER TO gitea_user;

--
-- Name: action_task_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.action_task_id_seq OWNED BY public.action_task.id;


--
-- Name: action_task_output; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.action_task_output (
    id bigint NOT NULL,
    task_id bigint,
    output_key character varying(255),
    output_value text
);


ALTER TABLE public.action_task_output OWNER TO gitea_user;

--
-- Name: action_task_output_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.action_task_output_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.action_task_output_id_seq OWNER TO gitea_user;

--
-- Name: action_task_output_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.action_task_output_id_seq OWNED BY public.action_task_output.id;


--
-- Name: action_task_step; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.action_task_step (
    id bigint NOT NULL,
    name character varying(255),
    task_id bigint,
    index bigint,
    repo_id bigint,
    status integer,
    log_index bigint,
    log_length bigint,
    started bigint,
    stopped bigint,
    created bigint,
    updated bigint
);


ALTER TABLE public.action_task_step OWNER TO gitea_user;

--
-- Name: action_task_step_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.action_task_step_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.action_task_step_id_seq OWNER TO gitea_user;

--
-- Name: action_task_step_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.action_task_step_id_seq OWNED BY public.action_task_step.id;


--
-- Name: action_tasks_version; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.action_tasks_version (
    id bigint NOT NULL,
    owner_id bigint,
    repo_id bigint,
    version bigint,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.action_tasks_version OWNER TO gitea_user;

--
-- Name: action_tasks_version_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.action_tasks_version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.action_tasks_version_id_seq OWNER TO gitea_user;

--
-- Name: action_tasks_version_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.action_tasks_version_id_seq OWNED BY public.action_tasks_version.id;


--
-- Name: action_variable; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.action_variable (
    id bigint NOT NULL,
    owner_id bigint,
    repo_id bigint,
    name character varying(255) NOT NULL,
    data text NOT NULL,
    description text,
    created_unix bigint NOT NULL,
    updated_unix bigint
);


ALTER TABLE public.action_variable OWNER TO gitea_user;

--
-- Name: action_variable_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.action_variable_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.action_variable_id_seq OWNER TO gitea_user;

--
-- Name: action_variable_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.action_variable_id_seq OWNED BY public.action_variable.id;


--
-- Name: app_state; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.app_state (
    id character varying(200) NOT NULL,
    revision bigint,
    content text
);


ALTER TABLE public.app_state OWNER TO gitea_user;

--
-- Name: attachment; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.attachment (
    id bigint NOT NULL,
    uuid uuid,
    repo_id bigint,
    issue_id bigint,
    release_id bigint,
    uploader_id bigint DEFAULT 0,
    comment_id bigint,
    name character varying(255),
    download_count bigint DEFAULT 0,
    size bigint DEFAULT 0,
    created_unix bigint
);


ALTER TABLE public.attachment OWNER TO gitea_user;

--
-- Name: attachment_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.attachment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.attachment_id_seq OWNER TO gitea_user;

--
-- Name: attachment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.attachment_id_seq OWNED BY public.attachment.id;


--
-- Name: auth_token; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.auth_token (
    id character varying(255) NOT NULL,
    token_hash character varying(255),
    user_id bigint,
    expires_unix bigint
);


ALTER TABLE public.auth_token OWNER TO gitea_user;

--
-- Name: badge; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.badge (
    id bigint NOT NULL,
    slug character varying(255),
    description character varying(255),
    image_url character varying(255)
);


ALTER TABLE public.badge OWNER TO gitea_user;

--
-- Name: badge_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.badge_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.badge_id_seq OWNER TO gitea_user;

--
-- Name: badge_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.badge_id_seq OWNED BY public.badge.id;


--
-- Name: branch; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.branch (
    id bigint NOT NULL,
    repo_id bigint,
    name character varying(255) NOT NULL,
    commit_id character varying(255),
    commit_message text,
    pusher_id bigint,
    is_deleted boolean,
    deleted_by_id bigint,
    deleted_unix bigint,
    commit_time bigint,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.branch OWNER TO gitea_user;

--
-- Name: branch_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.branch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.branch_id_seq OWNER TO gitea_user;

--
-- Name: branch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.branch_id_seq OWNED BY public.branch.id;


--
-- Name: collaboration; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.collaboration (
    id bigint NOT NULL,
    repo_id bigint NOT NULL,
    user_id bigint NOT NULL,
    mode integer DEFAULT 2 NOT NULL,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.collaboration OWNER TO gitea_user;

--
-- Name: collaboration_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.collaboration_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.collaboration_id_seq OWNER TO gitea_user;

--
-- Name: collaboration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.collaboration_id_seq OWNED BY public.collaboration.id;


--
-- Name: comment; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.comment (
    id bigint NOT NULL,
    type integer,
    poster_id bigint,
    original_author character varying(255),
    original_author_id bigint,
    issue_id bigint,
    label_id bigint,
    old_project_id bigint,
    project_id bigint,
    old_milestone_id bigint,
    milestone_id bigint,
    time_id bigint,
    assignee_id bigint,
    removed_assignee boolean,
    assignee_team_id bigint DEFAULT 0 NOT NULL,
    resolve_doer_id bigint,
    old_title character varying(255),
    new_title character varying(255),
    old_ref character varying(255),
    new_ref character varying(255),
    dependent_issue_id bigint,
    commit_id bigint,
    line bigint,
    tree_path character varying(255),
    content text,
    content_version integer DEFAULT 0 NOT NULL,
    patch text,
    created_unix bigint,
    updated_unix bigint,
    commit_sha character varying(64),
    review_id bigint,
    invalidated boolean,
    ref_repo_id bigint,
    ref_issue_id bigint,
    ref_comment_id bigint,
    ref_action smallint,
    ref_is_pull boolean,
    comment_meta_data text
);


ALTER TABLE public.comment OWNER TO gitea_user;

--
-- Name: comment_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.comment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.comment_id_seq OWNER TO gitea_user;

--
-- Name: comment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.comment_id_seq OWNED BY public.comment.id;


--
-- Name: commit_status; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.commit_status (
    id bigint NOT NULL,
    index bigint,
    repo_id bigint,
    state character varying(7) NOT NULL,
    sha character varying(64) NOT NULL,
    target_url text,
    description text,
    context_hash character varying(64),
    context text,
    creator_id bigint,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.commit_status OWNER TO gitea_user;

--
-- Name: commit_status_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.commit_status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.commit_status_id_seq OWNER TO gitea_user;

--
-- Name: commit_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.commit_status_id_seq OWNED BY public.commit_status.id;


--
-- Name: commit_status_index; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.commit_status_index (
    id bigint NOT NULL,
    repo_id bigint,
    sha character varying(255),
    max_index bigint
);


ALTER TABLE public.commit_status_index OWNER TO gitea_user;

--
-- Name: commit_status_index_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.commit_status_index_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.commit_status_index_id_seq OWNER TO gitea_user;

--
-- Name: commit_status_index_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.commit_status_index_id_seq OWNED BY public.commit_status_index.id;


--
-- Name: commit_status_summary; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.commit_status_summary (
    id bigint NOT NULL,
    repo_id bigint,
    sha character varying(64) NOT NULL,
    state character varying(7) NOT NULL,
    target_url text
);


ALTER TABLE public.commit_status_summary OWNER TO gitea_user;

--
-- Name: commit_status_summary_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.commit_status_summary_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.commit_status_summary_id_seq OWNER TO gitea_user;

--
-- Name: commit_status_summary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.commit_status_summary_id_seq OWNED BY public.commit_status_summary.id;


--
-- Name: dbfs_data; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.dbfs_data (
    id bigint NOT NULL,
    revision bigint NOT NULL,
    meta_id bigint NOT NULL,
    blob_offset bigint NOT NULL,
    blob_size bigint NOT NULL,
    blob_data bytea NOT NULL
);


ALTER TABLE public.dbfs_data OWNER TO gitea_user;

--
-- Name: dbfs_data_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.dbfs_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dbfs_data_id_seq OWNER TO gitea_user;

--
-- Name: dbfs_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.dbfs_data_id_seq OWNED BY public.dbfs_data.id;


--
-- Name: dbfs_meta; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.dbfs_meta (
    id bigint NOT NULL,
    full_path character varying(500) NOT NULL,
    block_size bigint NOT NULL,
    file_size bigint NOT NULL,
    create_timestamp bigint NOT NULL,
    modify_timestamp bigint NOT NULL
);


ALTER TABLE public.dbfs_meta OWNER TO gitea_user;

--
-- Name: dbfs_meta_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.dbfs_meta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dbfs_meta_id_seq OWNER TO gitea_user;

--
-- Name: dbfs_meta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.dbfs_meta_id_seq OWNED BY public.dbfs_meta.id;


--
-- Name: deploy_key; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.deploy_key (
    id bigint NOT NULL,
    key_id bigint,
    repo_id bigint,
    name character varying(255),
    fingerprint character varying(255),
    mode integer DEFAULT 1 NOT NULL,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.deploy_key OWNER TO gitea_user;

--
-- Name: deploy_key_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.deploy_key_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.deploy_key_id_seq OWNER TO gitea_user;

--
-- Name: deploy_key_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.deploy_key_id_seq OWNED BY public.deploy_key.id;


--
-- Name: email_address; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.email_address (
    id bigint NOT NULL,
    uid bigint NOT NULL,
    email character varying(255) NOT NULL,
    lower_email character varying(255) NOT NULL,
    is_activated boolean,
    is_primary boolean DEFAULT false NOT NULL
);


ALTER TABLE public.email_address OWNER TO gitea_user;

--
-- Name: email_address_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.email_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.email_address_id_seq OWNER TO gitea_user;

--
-- Name: email_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.email_address_id_seq OWNED BY public.email_address.id;


--
-- Name: email_hash; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.email_hash (
    hash character varying(32) NOT NULL,
    email character varying(255) NOT NULL
);


ALTER TABLE public.email_hash OWNER TO gitea_user;

--
-- Name: external_login_user; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.external_login_user (
    external_id character varying(255) NOT NULL,
    user_id bigint NOT NULL,
    login_source_id bigint NOT NULL,
    raw_data json,
    provider character varying(25),
    email character varying(255),
    name character varying(255),
    first_name character varying(255),
    last_name character varying(255),
    nick_name character varying(255),
    description character varying(255),
    avatar_url text,
    location character varying(255),
    access_token text,
    access_token_secret text,
    refresh_token text,
    expires_at timestamp without time zone
);


ALTER TABLE public.external_login_user OWNER TO gitea_user;

--
-- Name: follow; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.follow (
    id bigint NOT NULL,
    user_id bigint,
    follow_id bigint,
    created_unix bigint
);


ALTER TABLE public.follow OWNER TO gitea_user;

--
-- Name: follow_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.follow_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.follow_id_seq OWNER TO gitea_user;

--
-- Name: follow_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.follow_id_seq OWNED BY public.follow.id;


--
-- Name: gpg_key; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.gpg_key (
    id bigint NOT NULL,
    owner_id bigint NOT NULL,
    key_id character(16) NOT NULL,
    primary_key_id character(16),
    content text NOT NULL,
    created_unix bigint,
    expired_unix bigint,
    added_unix bigint,
    emails text,
    verified boolean DEFAULT false NOT NULL,
    can_sign boolean,
    can_encrypt_comms boolean,
    can_encrypt_storage boolean,
    can_certify boolean
);


ALTER TABLE public.gpg_key OWNER TO gitea_user;

--
-- Name: gpg_key_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.gpg_key_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gpg_key_id_seq OWNER TO gitea_user;

--
-- Name: gpg_key_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.gpg_key_id_seq OWNED BY public.gpg_key.id;


--
-- Name: gpg_key_import; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.gpg_key_import (
    key_id character(16) NOT NULL,
    content text NOT NULL
);


ALTER TABLE public.gpg_key_import OWNER TO gitea_user;

--
-- Name: hook_task; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.hook_task (
    id bigint NOT NULL,
    hook_id bigint,
    uuid character varying(255),
    payload_content text,
    payload_version integer DEFAULT 1,
    event_type character varying(255),
    is_delivered boolean,
    delivered bigint,
    is_succeed boolean,
    request_content text,
    response_content text
);


ALTER TABLE public.hook_task OWNER TO gitea_user;

--
-- Name: hook_task_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.hook_task_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.hook_task_id_seq OWNER TO gitea_user;

--
-- Name: hook_task_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.hook_task_id_seq OWNED BY public.hook_task.id;


--
-- Name: issue; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.issue (
    id bigint NOT NULL,
    repo_id bigint,
    index bigint,
    poster_id bigint,
    original_author character varying(255),
    original_author_id bigint,
    name character varying(255),
    content text,
    content_version integer DEFAULT 0 NOT NULL,
    milestone_id bigint,
    priority integer,
    is_closed boolean,
    is_pull boolean,
    num_comments integer,
    ref character varying(255),
    deadline_unix bigint,
    created_unix bigint,
    updated_unix bigint,
    closed_unix bigint,
    is_locked boolean DEFAULT false NOT NULL,
    time_estimate bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.issue OWNER TO gitea_user;

--
-- Name: issue_assignees; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.issue_assignees (
    id bigint NOT NULL,
    assignee_id bigint,
    issue_id bigint
);


ALTER TABLE public.issue_assignees OWNER TO gitea_user;

--
-- Name: issue_assignees_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.issue_assignees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.issue_assignees_id_seq OWNER TO gitea_user;

--
-- Name: issue_assignees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.issue_assignees_id_seq OWNED BY public.issue_assignees.id;


--
-- Name: issue_content_history; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.issue_content_history (
    id bigint NOT NULL,
    poster_id bigint,
    issue_id bigint,
    comment_id bigint,
    edited_unix bigint,
    content_text text,
    is_first_created boolean,
    is_deleted boolean
);


ALTER TABLE public.issue_content_history OWNER TO gitea_user;

--
-- Name: issue_content_history_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.issue_content_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.issue_content_history_id_seq OWNER TO gitea_user;

--
-- Name: issue_content_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.issue_content_history_id_seq OWNED BY public.issue_content_history.id;


--
-- Name: issue_dependency; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.issue_dependency (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    issue_id bigint NOT NULL,
    dependency_id bigint NOT NULL,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.issue_dependency OWNER TO gitea_user;

--
-- Name: issue_dependency_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.issue_dependency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.issue_dependency_id_seq OWNER TO gitea_user;

--
-- Name: issue_dependency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.issue_dependency_id_seq OWNED BY public.issue_dependency.id;


--
-- Name: issue_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.issue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.issue_id_seq OWNER TO gitea_user;

--
-- Name: issue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.issue_id_seq OWNED BY public.issue.id;


--
-- Name: issue_index; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.issue_index (
    group_id bigint NOT NULL,
    max_index bigint
);


ALTER TABLE public.issue_index OWNER TO gitea_user;

--
-- Name: issue_label; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.issue_label (
    id bigint NOT NULL,
    issue_id bigint,
    label_id bigint
);


ALTER TABLE public.issue_label OWNER TO gitea_user;

--
-- Name: issue_label_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.issue_label_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.issue_label_id_seq OWNER TO gitea_user;

--
-- Name: issue_label_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.issue_label_id_seq OWNED BY public.issue_label.id;


--
-- Name: issue_pin; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.issue_pin (
    id bigint NOT NULL,
    repo_id bigint NOT NULL,
    issue_id bigint NOT NULL,
    is_pull boolean NOT NULL,
    pin_order integer DEFAULT 0
);


ALTER TABLE public.issue_pin OWNER TO gitea_user;

--
-- Name: issue_pin_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.issue_pin_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.issue_pin_id_seq OWNER TO gitea_user;

--
-- Name: issue_pin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.issue_pin_id_seq OWNED BY public.issue_pin.id;


--
-- Name: issue_user; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.issue_user (
    id bigint NOT NULL,
    uid bigint,
    issue_id bigint,
    is_read boolean,
    is_mentioned boolean
);


ALTER TABLE public.issue_user OWNER TO gitea_user;

--
-- Name: issue_user_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.issue_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.issue_user_id_seq OWNER TO gitea_user;

--
-- Name: issue_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.issue_user_id_seq OWNED BY public.issue_user.id;


--
-- Name: issue_watch; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.issue_watch (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    issue_id bigint NOT NULL,
    is_watching boolean NOT NULL,
    created_unix bigint NOT NULL,
    updated_unix bigint NOT NULL
);


ALTER TABLE public.issue_watch OWNER TO gitea_user;

--
-- Name: issue_watch_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.issue_watch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.issue_watch_id_seq OWNER TO gitea_user;

--
-- Name: issue_watch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.issue_watch_id_seq OWNED BY public.issue_watch.id;


--
-- Name: label; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.label (
    id bigint NOT NULL,
    repo_id bigint,
    org_id bigint,
    name character varying(255),
    exclusive boolean,
    exclusive_order integer DEFAULT 0,
    description character varying(255),
    color character varying(7),
    num_issues integer,
    num_closed_issues integer,
    created_unix bigint,
    updated_unix bigint,
    archived_unix bigint
);


ALTER TABLE public.label OWNER TO gitea_user;

--
-- Name: label_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.label_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.label_id_seq OWNER TO gitea_user;

--
-- Name: label_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.label_id_seq OWNED BY public.label.id;


--
-- Name: language_stat; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.language_stat (
    id bigint NOT NULL,
    repo_id bigint NOT NULL,
    commit_id character varying(255),
    is_primary boolean,
    language character varying(50) NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    created_unix bigint
);


ALTER TABLE public.language_stat OWNER TO gitea_user;

--
-- Name: language_stat_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.language_stat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.language_stat_id_seq OWNER TO gitea_user;

--
-- Name: language_stat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.language_stat_id_seq OWNED BY public.language_stat.id;


--
-- Name: lfs_lock; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.lfs_lock (
    id bigint NOT NULL,
    repo_id bigint NOT NULL,
    owner_id bigint NOT NULL,
    path text,
    created timestamp without time zone
);


ALTER TABLE public.lfs_lock OWNER TO gitea_user;

--
-- Name: lfs_lock_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.lfs_lock_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lfs_lock_id_seq OWNER TO gitea_user;

--
-- Name: lfs_lock_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.lfs_lock_id_seq OWNED BY public.lfs_lock.id;


--
-- Name: lfs_meta_object; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.lfs_meta_object (
    id bigint NOT NULL,
    oid character varying(255) NOT NULL,
    size bigint NOT NULL,
    repository_id bigint NOT NULL,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.lfs_meta_object OWNER TO gitea_user;

--
-- Name: lfs_meta_object_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.lfs_meta_object_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lfs_meta_object_id_seq OWNER TO gitea_user;

--
-- Name: lfs_meta_object_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.lfs_meta_object_id_seq OWNED BY public.lfs_meta_object.id;


--
-- Name: login_source; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.login_source (
    id bigint NOT NULL,
    type integer,
    name character varying(255),
    is_active boolean DEFAULT false NOT NULL,
    is_sync_enabled boolean DEFAULT false NOT NULL,
    two_factor_policy character varying(255) DEFAULT ''::character varying NOT NULL,
    cfg text,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.login_source OWNER TO gitea_user;

--
-- Name: login_source_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.login_source_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.login_source_id_seq OWNER TO gitea_user;

--
-- Name: login_source_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.login_source_id_seq OWNED BY public.login_source.id;


--
-- Name: milestone; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.milestone (
    id bigint NOT NULL,
    repo_id bigint,
    name character varying(255),
    content text,
    is_closed boolean,
    num_issues integer,
    num_closed_issues integer,
    completeness integer,
    created_unix bigint,
    updated_unix bigint,
    deadline_unix bigint,
    closed_date_unix bigint
);


ALTER TABLE public.milestone OWNER TO gitea_user;

--
-- Name: milestone_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.milestone_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.milestone_id_seq OWNER TO gitea_user;

--
-- Name: milestone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.milestone_id_seq OWNED BY public.milestone.id;


--
-- Name: mirror; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.mirror (
    id bigint NOT NULL,
    repo_id bigint,
    "interval" bigint,
    enable_prune boolean DEFAULT true NOT NULL,
    updated_unix bigint,
    next_update_unix bigint,
    lfs_enabled boolean DEFAULT false NOT NULL,
    lfs_endpoint text,
    remote_address character varying(2048)
);


ALTER TABLE public.mirror OWNER TO gitea_user;

--
-- Name: mirror_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.mirror_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mirror_id_seq OWNER TO gitea_user;

--
-- Name: mirror_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.mirror_id_seq OWNED BY public.mirror.id;


--
-- Name: notice; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.notice (
    id bigint NOT NULL,
    type integer,
    description text,
    created_unix bigint
);


ALTER TABLE public.notice OWNER TO gitea_user;

--
-- Name: notice_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.notice_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notice_id_seq OWNER TO gitea_user;

--
-- Name: notice_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.notice_id_seq OWNED BY public.notice.id;


--
-- Name: notification; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.notification (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    repo_id bigint NOT NULL,
    status smallint NOT NULL,
    source smallint NOT NULL,
    issue_id bigint NOT NULL,
    commit_id character varying(255),
    comment_id bigint,
    updated_by bigint NOT NULL,
    created_unix bigint NOT NULL,
    updated_unix bigint NOT NULL
);


ALTER TABLE public.notification OWNER TO gitea_user;

--
-- Name: notification_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.notification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notification_id_seq OWNER TO gitea_user;

--
-- Name: notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.notification_id_seq OWNED BY public.notification.id;


--
-- Name: oauth2_application; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.oauth2_application (
    id bigint NOT NULL,
    uid bigint,
    name character varying(255),
    client_id character varying(255),
    client_secret character varying(255),
    confidential_client boolean DEFAULT true NOT NULL,
    skip_secondary_authorization boolean DEFAULT false NOT NULL,
    redirect_uris text,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.oauth2_application OWNER TO gitea_user;

--
-- Name: oauth2_application_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.oauth2_application_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.oauth2_application_id_seq OWNER TO gitea_user;

--
-- Name: oauth2_application_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.oauth2_application_id_seq OWNED BY public.oauth2_application.id;


--
-- Name: oauth2_authorization_code; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.oauth2_authorization_code (
    id bigint NOT NULL,
    grant_id bigint,
    code character varying(255),
    code_challenge character varying(255),
    code_challenge_method character varying(255),
    redirect_uri character varying(255),
    valid_until bigint
);


ALTER TABLE public.oauth2_authorization_code OWNER TO gitea_user;

--
-- Name: oauth2_authorization_code_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.oauth2_authorization_code_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.oauth2_authorization_code_id_seq OWNER TO gitea_user;

--
-- Name: oauth2_authorization_code_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.oauth2_authorization_code_id_seq OWNED BY public.oauth2_authorization_code.id;


--
-- Name: oauth2_grant; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.oauth2_grant (
    id bigint NOT NULL,
    user_id bigint,
    application_id bigint,
    counter bigint DEFAULT 1 NOT NULL,
    scope text,
    nonce text,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.oauth2_grant OWNER TO gitea_user;

--
-- Name: oauth2_grant_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.oauth2_grant_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.oauth2_grant_id_seq OWNER TO gitea_user;

--
-- Name: oauth2_grant_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.oauth2_grant_id_seq OWNED BY public.oauth2_grant.id;


--
-- Name: org_user; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.org_user (
    id bigint NOT NULL,
    uid bigint,
    org_id bigint,
    is_public boolean
);


ALTER TABLE public.org_user OWNER TO gitea_user;

--
-- Name: org_user_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.org_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.org_user_id_seq OWNER TO gitea_user;

--
-- Name: org_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.org_user_id_seq OWNED BY public.org_user.id;


--
-- Name: package; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.package (
    id bigint NOT NULL,
    owner_id bigint NOT NULL,
    repo_id bigint,
    type character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    lower_name character varying(255) NOT NULL,
    semver_compatible boolean DEFAULT false NOT NULL,
    is_internal boolean DEFAULT false NOT NULL
);


ALTER TABLE public.package OWNER TO gitea_user;

--
-- Name: package_blob; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.package_blob (
    id bigint NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    hash_md5 character(32) NOT NULL,
    hash_sha1 character(40) NOT NULL,
    hash_sha256 character(64) NOT NULL,
    hash_sha512 character(128) NOT NULL,
    created_unix bigint NOT NULL
);


ALTER TABLE public.package_blob OWNER TO gitea_user;

--
-- Name: package_blob_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.package_blob_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.package_blob_id_seq OWNER TO gitea_user;

--
-- Name: package_blob_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.package_blob_id_seq OWNED BY public.package_blob.id;


--
-- Name: package_blob_upload; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.package_blob_upload (
    id character varying(255) NOT NULL,
    bytes_received bigint DEFAULT 0 NOT NULL,
    hash_state_bytes bytea,
    created_unix bigint NOT NULL,
    updated_unix bigint NOT NULL
);


ALTER TABLE public.package_blob_upload OWNER TO gitea_user;

--
-- Name: package_cleanup_rule; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.package_cleanup_rule (
    id bigint NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    owner_id bigint DEFAULT 0 NOT NULL,
    type character varying(255) NOT NULL,
    keep_count integer DEFAULT 0 NOT NULL,
    keep_pattern character varying(255) DEFAULT ''::character varying NOT NULL,
    remove_days integer DEFAULT 0 NOT NULL,
    remove_pattern character varying(255) DEFAULT ''::character varying NOT NULL,
    match_full_name boolean DEFAULT false NOT NULL,
    created_unix bigint DEFAULT 0 NOT NULL,
    updated_unix bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.package_cleanup_rule OWNER TO gitea_user;

--
-- Name: package_cleanup_rule_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.package_cleanup_rule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.package_cleanup_rule_id_seq OWNER TO gitea_user;

--
-- Name: package_cleanup_rule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.package_cleanup_rule_id_seq OWNED BY public.package_cleanup_rule.id;


--
-- Name: package_file; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.package_file (
    id bigint NOT NULL,
    version_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    lower_name character varying(255) NOT NULL,
    composite_key character varying(255),
    is_lead boolean DEFAULT false NOT NULL,
    created_unix bigint NOT NULL
);


ALTER TABLE public.package_file OWNER TO gitea_user;

--
-- Name: package_file_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.package_file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.package_file_id_seq OWNER TO gitea_user;

--
-- Name: package_file_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.package_file_id_seq OWNED BY public.package_file.id;


--
-- Name: package_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.package_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.package_id_seq OWNER TO gitea_user;

--
-- Name: package_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.package_id_seq OWNED BY public.package.id;


--
-- Name: package_property; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.package_property (
    id bigint NOT NULL,
    ref_type bigint NOT NULL,
    ref_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.package_property OWNER TO gitea_user;

--
-- Name: package_property_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.package_property_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.package_property_id_seq OWNER TO gitea_user;

--
-- Name: package_property_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.package_property_id_seq OWNED BY public.package_property.id;


--
-- Name: package_version; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.package_version (
    id bigint NOT NULL,
    package_id bigint NOT NULL,
    creator_id bigint DEFAULT 0 NOT NULL,
    version character varying(255) NOT NULL,
    lower_version character varying(255) NOT NULL,
    created_unix bigint NOT NULL,
    is_internal boolean DEFAULT false NOT NULL,
    metadata_json text,
    download_count bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.package_version OWNER TO gitea_user;

--
-- Name: package_version_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.package_version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.package_version_id_seq OWNER TO gitea_user;

--
-- Name: package_version_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.package_version_id_seq OWNED BY public.package_version.id;


--
-- Name: project; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.project (
    id bigint NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    owner_id bigint,
    repo_id bigint,
    creator_id bigint NOT NULL,
    is_closed boolean,
    board_type bigint,
    card_type bigint,
    type bigint,
    created_unix bigint,
    updated_unix bigint,
    closed_date_unix bigint
);


ALTER TABLE public.project OWNER TO gitea_user;

--
-- Name: project_board; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.project_board (
    id bigint NOT NULL,
    title character varying(255),
    "default" boolean DEFAULT false NOT NULL,
    sorting integer DEFAULT 0 NOT NULL,
    color character varying(7),
    project_id bigint NOT NULL,
    creator_id bigint NOT NULL,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.project_board OWNER TO gitea_user;

--
-- Name: project_board_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.project_board_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.project_board_id_seq OWNER TO gitea_user;

--
-- Name: project_board_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.project_board_id_seq OWNED BY public.project_board.id;


--
-- Name: project_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.project_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.project_id_seq OWNER TO gitea_user;

--
-- Name: project_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.project_id_seq OWNED BY public.project.id;


--
-- Name: project_issue; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.project_issue (
    id bigint NOT NULL,
    issue_id bigint,
    project_id bigint,
    project_board_id bigint,
    sorting bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.project_issue OWNER TO gitea_user;

--
-- Name: project_issue_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.project_issue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.project_issue_id_seq OWNER TO gitea_user;

--
-- Name: project_issue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.project_issue_id_seq OWNED BY public.project_issue.id;


--
-- Name: protected_branch; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.protected_branch (
    id bigint NOT NULL,
    repo_id bigint,
    branch_name character varying(255),
    priority bigint DEFAULT 0 NOT NULL,
    can_push boolean DEFAULT false NOT NULL,
    enable_whitelist boolean,
    whitelist_user_i_ds text,
    whitelist_team_i_ds text,
    enable_merge_whitelist boolean DEFAULT false NOT NULL,
    whitelist_deploy_keys boolean DEFAULT false NOT NULL,
    merge_whitelist_user_i_ds text,
    merge_whitelist_team_i_ds text,
    can_force_push boolean DEFAULT false NOT NULL,
    enable_force_push_allowlist boolean DEFAULT false NOT NULL,
    force_push_allowlist_user_i_ds text,
    force_push_allowlist_team_i_ds text,
    force_push_allowlist_deploy_keys boolean DEFAULT false NOT NULL,
    enable_status_check boolean DEFAULT false NOT NULL,
    status_check_contexts text,
    enable_approvals_whitelist boolean DEFAULT false NOT NULL,
    approvals_whitelist_user_i_ds text,
    approvals_whitelist_team_i_ds text,
    required_approvals bigint DEFAULT 0 NOT NULL,
    block_on_rejected_reviews boolean DEFAULT false NOT NULL,
    block_on_official_review_requests boolean DEFAULT false NOT NULL,
    block_on_outdated_branch boolean DEFAULT false NOT NULL,
    dismiss_stale_approvals boolean DEFAULT false NOT NULL,
    ignore_stale_approvals boolean DEFAULT false NOT NULL,
    require_signed_commits boolean DEFAULT false NOT NULL,
    protected_file_patterns text,
    unprotected_file_patterns text,
    block_admin_merge_override boolean DEFAULT false NOT NULL,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.protected_branch OWNER TO gitea_user;

--
-- Name: protected_branch_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.protected_branch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.protected_branch_id_seq OWNER TO gitea_user;

--
-- Name: protected_branch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.protected_branch_id_seq OWNED BY public.protected_branch.id;


--
-- Name: protected_tag; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.protected_tag (
    id bigint NOT NULL,
    repo_id bigint,
    name_pattern character varying(255),
    allowlist_user_i_ds text,
    allowlist_team_i_ds text,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.protected_tag OWNER TO gitea_user;

--
-- Name: protected_tag_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.protected_tag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.protected_tag_id_seq OWNER TO gitea_user;

--
-- Name: protected_tag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.protected_tag_id_seq OWNED BY public.protected_tag.id;


--
-- Name: public_key; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.public_key (
    id bigint NOT NULL,
    owner_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    fingerprint character varying(255) NOT NULL,
    content text NOT NULL,
    mode integer DEFAULT 2 NOT NULL,
    type integer DEFAULT 1 NOT NULL,
    login_source_id bigint DEFAULT 0 NOT NULL,
    created_unix bigint,
    updated_unix bigint,
    verified boolean DEFAULT false NOT NULL
);


ALTER TABLE public.public_key OWNER TO gitea_user;

--
-- Name: public_key_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.public_key_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.public_key_id_seq OWNER TO gitea_user;

--
-- Name: public_key_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.public_key_id_seq OWNED BY public.public_key.id;


--
-- Name: pull_auto_merge; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.pull_auto_merge (
    id bigint NOT NULL,
    pull_id bigint,
    doer_id bigint NOT NULL,
    merge_style character varying(30),
    message text,
    delete_branch_after_merge boolean,
    created_unix bigint
);


ALTER TABLE public.pull_auto_merge OWNER TO gitea_user;

--
-- Name: pull_auto_merge_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.pull_auto_merge_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pull_auto_merge_id_seq OWNER TO gitea_user;

--
-- Name: pull_auto_merge_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.pull_auto_merge_id_seq OWNED BY public.pull_auto_merge.id;


--
-- Name: pull_request; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.pull_request (
    id bigint NOT NULL,
    type integer,
    status integer,
    conflicted_files json,
    commits_ahead integer,
    commits_behind integer,
    changed_protected_files json,
    issue_id bigint,
    index bigint,
    head_repo_id bigint,
    base_repo_id bigint,
    head_branch character varying(255),
    base_branch character varying(255),
    merge_base character varying(64),
    allow_maintainer_edit boolean DEFAULT false NOT NULL,
    has_merged boolean,
    merged_commit_id character varying(64),
    merger_id bigint,
    merged_unix bigint,
    flow integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.pull_request OWNER TO gitea_user;

--
-- Name: pull_request_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.pull_request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pull_request_id_seq OWNER TO gitea_user;

--
-- Name: pull_request_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.pull_request_id_seq OWNED BY public.pull_request.id;


--
-- Name: push_mirror; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.push_mirror (
    id bigint NOT NULL,
    repo_id bigint,
    remote_name character varying(255),
    remote_address character varying(2048),
    sync_on_commit boolean DEFAULT true NOT NULL,
    "interval" bigint,
    created_unix bigint,
    last_update bigint,
    last_error text
);


ALTER TABLE public.push_mirror OWNER TO gitea_user;

--
-- Name: push_mirror_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.push_mirror_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.push_mirror_id_seq OWNER TO gitea_user;

--
-- Name: push_mirror_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.push_mirror_id_seq OWNED BY public.push_mirror.id;


--
-- Name: reaction; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.reaction (
    id bigint NOT NULL,
    type character varying(255) NOT NULL,
    issue_id bigint NOT NULL,
    comment_id bigint,
    user_id bigint NOT NULL,
    original_author_id bigint DEFAULT 0 NOT NULL,
    original_author character varying(255),
    created_unix bigint
);


ALTER TABLE public.reaction OWNER TO gitea_user;

--
-- Name: reaction_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.reaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reaction_id_seq OWNER TO gitea_user;

--
-- Name: reaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.reaction_id_seq OWNED BY public.reaction.id;


--
-- Name: release; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.release (
    id bigint NOT NULL,
    repo_id bigint,
    publisher_id bigint,
    tag_name character varying(255),
    original_author character varying(255),
    original_author_id bigint,
    lower_tag_name character varying(255),
    target character varying(255),
    title character varying(255),
    sha1 character varying(64),
    num_commits bigint,
    note text,
    is_draft boolean DEFAULT false NOT NULL,
    is_prerelease boolean DEFAULT false NOT NULL,
    is_tag boolean DEFAULT false NOT NULL,
    created_unix bigint
);


ALTER TABLE public.release OWNER TO gitea_user;

--
-- Name: release_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.release_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.release_id_seq OWNER TO gitea_user;

--
-- Name: release_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.release_id_seq OWNED BY public.release.id;


--
-- Name: renamed_branch; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.renamed_branch (
    id bigint NOT NULL,
    repo_id bigint NOT NULL,
    "from" character varying(255),
    "to" character varying(255),
    created_unix bigint
);


ALTER TABLE public.renamed_branch OWNER TO gitea_user;

--
-- Name: renamed_branch_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.renamed_branch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.renamed_branch_id_seq OWNER TO gitea_user;

--
-- Name: renamed_branch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.renamed_branch_id_seq OWNED BY public.renamed_branch.id;


--
-- Name: repo_archiver; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.repo_archiver (
    id bigint NOT NULL,
    repo_id bigint,
    type integer,
    status integer,
    commit_id character varying(64),
    created_unix bigint NOT NULL
);


ALTER TABLE public.repo_archiver OWNER TO gitea_user;

--
-- Name: repo_archiver_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.repo_archiver_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.repo_archiver_id_seq OWNER TO gitea_user;

--
-- Name: repo_archiver_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.repo_archiver_id_seq OWNED BY public.repo_archiver.id;


--
-- Name: repo_indexer_status; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.repo_indexer_status (
    id bigint NOT NULL,
    repo_id bigint,
    commit_sha character varying(64),
    indexer_type integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.repo_indexer_status OWNER TO gitea_user;

--
-- Name: repo_indexer_status_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.repo_indexer_status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.repo_indexer_status_id_seq OWNER TO gitea_user;

--
-- Name: repo_indexer_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.repo_indexer_status_id_seq OWNED BY public.repo_indexer_status.id;


--
-- Name: repo_license; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.repo_license (
    id bigint NOT NULL,
    repo_id bigint NOT NULL,
    commit_id character varying(255),
    license character varying(255) NOT NULL,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.repo_license OWNER TO gitea_user;

--
-- Name: repo_license_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.repo_license_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.repo_license_id_seq OWNER TO gitea_user;

--
-- Name: repo_license_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.repo_license_id_seq OWNED BY public.repo_license.id;


--
-- Name: repo_redirect; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.repo_redirect (
    id bigint NOT NULL,
    owner_id bigint,
    lower_name character varying(255) NOT NULL,
    redirect_repo_id bigint
);


ALTER TABLE public.repo_redirect OWNER TO gitea_user;

--
-- Name: repo_redirect_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.repo_redirect_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.repo_redirect_id_seq OWNER TO gitea_user;

--
-- Name: repo_redirect_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.repo_redirect_id_seq OWNED BY public.repo_redirect.id;


--
-- Name: repo_topic; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.repo_topic (
    repo_id bigint NOT NULL,
    topic_id bigint NOT NULL
);


ALTER TABLE public.repo_topic OWNER TO gitea_user;

--
-- Name: repo_transfer; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.repo_transfer (
    id bigint NOT NULL,
    doer_id bigint,
    recipient_id bigint,
    repo_id bigint,
    team_i_ds text,
    created_unix bigint NOT NULL,
    updated_unix bigint NOT NULL
);


ALTER TABLE public.repo_transfer OWNER TO gitea_user;

--
-- Name: repo_transfer_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.repo_transfer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.repo_transfer_id_seq OWNER TO gitea_user;

--
-- Name: repo_transfer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.repo_transfer_id_seq OWNED BY public.repo_transfer.id;


--
-- Name: repo_unit; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.repo_unit (
    id bigint NOT NULL,
    repo_id bigint,
    type integer,
    config text,
    created_unix bigint,
    anonymous_access_mode integer DEFAULT 0 NOT NULL,
    everyone_access_mode integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.repo_unit OWNER TO gitea_user;

--
-- Name: repo_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.repo_unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.repo_unit_id_seq OWNER TO gitea_user;

--
-- Name: repo_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.repo_unit_id_seq OWNED BY public.repo_unit.id;


--
-- Name: repository; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.repository (
    id bigint NOT NULL,
    owner_id bigint,
    owner_name character varying(255),
    lower_name character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    website character varying(2048),
    original_service_type integer,
    original_url character varying(2048),
    default_branch character varying(255),
    default_wiki_branch character varying(255),
    num_watches integer,
    num_stars integer,
    num_forks integer,
    num_issues integer,
    num_closed_issues integer,
    num_pulls integer,
    num_closed_pulls integer,
    num_milestones integer DEFAULT 0 NOT NULL,
    num_closed_milestones integer DEFAULT 0 NOT NULL,
    num_projects integer DEFAULT 0 NOT NULL,
    num_closed_projects integer DEFAULT 0 NOT NULL,
    num_action_runs integer DEFAULT 0 NOT NULL,
    num_closed_action_runs integer DEFAULT 0 NOT NULL,
    is_private boolean,
    is_empty boolean,
    is_archived boolean,
    is_mirror boolean,
    status integer DEFAULT 0 NOT NULL,
    is_fork boolean DEFAULT false NOT NULL,
    fork_id bigint,
    is_template boolean DEFAULT false NOT NULL,
    template_id bigint,
    size bigint DEFAULT 0 NOT NULL,
    git_size bigint DEFAULT 0 NOT NULL,
    lfs_size bigint DEFAULT 0 NOT NULL,
    is_fsck_enabled boolean DEFAULT true NOT NULL,
    close_issues_via_commit_in_any_branch boolean DEFAULT false NOT NULL,
    topics json,
    object_format_name character varying(6) DEFAULT 'sha1'::character varying NOT NULL,
    trust_model integer,
    avatar character varying(64),
    created_unix bigint,
    updated_unix bigint,
    archived_unix bigint DEFAULT 0
);


ALTER TABLE public.repository OWNER TO gitea_user;

--
-- Name: repository_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.repository_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.repository_id_seq OWNER TO gitea_user;

--
-- Name: repository_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.repository_id_seq OWNED BY public.repository.id;


--
-- Name: review; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.review (
    id bigint NOT NULL,
    type integer,
    reviewer_id bigint,
    reviewer_team_id bigint DEFAULT 0 NOT NULL,
    original_author character varying(255),
    original_author_id bigint,
    issue_id bigint,
    content text,
    official boolean DEFAULT false NOT NULL,
    commit_id character varying(64),
    stale boolean DEFAULT false NOT NULL,
    dismissed boolean DEFAULT false NOT NULL,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.review OWNER TO gitea_user;

--
-- Name: review_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.review_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.review_id_seq OWNER TO gitea_user;

--
-- Name: review_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.review_id_seq OWNED BY public.review.id;


--
-- Name: review_state; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.review_state (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    pull_id bigint DEFAULT 0 NOT NULL,
    commit_sha character varying(64) NOT NULL,
    updated_files json NOT NULL,
    updated_unix bigint
);


ALTER TABLE public.review_state OWNER TO gitea_user;

--
-- Name: review_state_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.review_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.review_state_id_seq OWNER TO gitea_user;

--
-- Name: review_state_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.review_state_id_seq OWNED BY public.review_state.id;


--
-- Name: secret; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.secret (
    id bigint NOT NULL,
    owner_id bigint NOT NULL,
    repo_id bigint DEFAULT 0 NOT NULL,
    name character varying(255) NOT NULL,
    data text,
    description text,
    created_unix bigint NOT NULL
);


ALTER TABLE public.secret OWNER TO gitea_user;

--
-- Name: secret_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.secret_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.secret_id_seq OWNER TO gitea_user;

--
-- Name: secret_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.secret_id_seq OWNED BY public.secret.id;


--
-- Name: session; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.session (
    key character(16) NOT NULL,
    data bytea,
    expiry bigint
);


ALTER TABLE public.session OWNER TO gitea_user;

--
-- Name: star; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.star (
    id bigint NOT NULL,
    uid bigint,
    repo_id bigint,
    created_unix bigint
);


ALTER TABLE public.star OWNER TO gitea_user;

--
-- Name: star_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.star_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.star_id_seq OWNER TO gitea_user;

--
-- Name: star_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.star_id_seq OWNED BY public.star.id;


--
-- Name: stopwatch; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.stopwatch (
    id bigint NOT NULL,
    issue_id bigint,
    user_id bigint,
    created_unix bigint
);


ALTER TABLE public.stopwatch OWNER TO gitea_user;

--
-- Name: stopwatch_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.stopwatch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.stopwatch_id_seq OWNER TO gitea_user;

--
-- Name: stopwatch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.stopwatch_id_seq OWNED BY public.stopwatch.id;


--
-- Name: system_setting; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.system_setting (
    id bigint NOT NULL,
    setting_key character varying(255),
    setting_value text,
    version integer,
    created bigint,
    updated bigint
);


ALTER TABLE public.system_setting OWNER TO gitea_user;

--
-- Name: system_setting_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.system_setting_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_setting_id_seq OWNER TO gitea_user;

--
-- Name: system_setting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.system_setting_id_seq OWNED BY public.system_setting.id;


--
-- Name: task; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.task (
    id bigint NOT NULL,
    doer_id bigint,
    owner_id bigint,
    repo_id bigint,
    type integer,
    status integer,
    start_time bigint,
    end_time bigint,
    payload_content text,
    message text,
    created bigint
);


ALTER TABLE public.task OWNER TO gitea_user;

--
-- Name: task_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.task_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.task_id_seq OWNER TO gitea_user;

--
-- Name: task_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.task_id_seq OWNED BY public.task.id;


--
-- Name: team; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.team (
    id bigint NOT NULL,
    org_id bigint,
    lower_name character varying(255),
    name character varying(255),
    description character varying(255),
    authorize integer,
    num_repos integer,
    num_members integer,
    includes_all_repositories boolean DEFAULT false NOT NULL,
    can_create_org_repo boolean DEFAULT false NOT NULL
);


ALTER TABLE public.team OWNER TO gitea_user;

--
-- Name: team_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.team_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.team_id_seq OWNER TO gitea_user;

--
-- Name: team_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.team_id_seq OWNED BY public.team.id;


--
-- Name: team_invite; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.team_invite (
    id bigint NOT NULL,
    token character varying(255) DEFAULT ''::character varying NOT NULL,
    inviter_id bigint DEFAULT 0 NOT NULL,
    org_id bigint DEFAULT 0 NOT NULL,
    team_id bigint DEFAULT 0 NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.team_invite OWNER TO gitea_user;

--
-- Name: team_invite_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.team_invite_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.team_invite_id_seq OWNER TO gitea_user;

--
-- Name: team_invite_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.team_invite_id_seq OWNED BY public.team_invite.id;


--
-- Name: team_repo; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.team_repo (
    id bigint NOT NULL,
    org_id bigint,
    team_id bigint,
    repo_id bigint
);


ALTER TABLE public.team_repo OWNER TO gitea_user;

--
-- Name: team_repo_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.team_repo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.team_repo_id_seq OWNER TO gitea_user;

--
-- Name: team_repo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.team_repo_id_seq OWNED BY public.team_repo.id;


--
-- Name: team_unit; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.team_unit (
    id bigint NOT NULL,
    org_id bigint,
    team_id bigint,
    type integer,
    access_mode integer
);


ALTER TABLE public.team_unit OWNER TO gitea_user;

--
-- Name: team_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.team_unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.team_unit_id_seq OWNER TO gitea_user;

--
-- Name: team_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.team_unit_id_seq OWNED BY public.team_unit.id;


--
-- Name: team_user; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.team_user (
    id bigint NOT NULL,
    org_id bigint,
    team_id bigint,
    uid bigint
);


ALTER TABLE public.team_user OWNER TO gitea_user;

--
-- Name: team_user_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.team_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.team_user_id_seq OWNER TO gitea_user;

--
-- Name: team_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.team_user_id_seq OWNED BY public.team_user.id;


--
-- Name: topic; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.topic (
    id bigint NOT NULL,
    name character varying(50),
    repo_count integer,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.topic OWNER TO gitea_user;

--
-- Name: topic_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.topic_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.topic_id_seq OWNER TO gitea_user;

--
-- Name: topic_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.topic_id_seq OWNED BY public.topic.id;


--
-- Name: tracked_time; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.tracked_time (
    id bigint NOT NULL,
    issue_id bigint,
    user_id bigint,
    created_unix bigint,
    "time" bigint NOT NULL,
    deleted boolean DEFAULT false NOT NULL
);


ALTER TABLE public.tracked_time OWNER TO gitea_user;

--
-- Name: tracked_time_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.tracked_time_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tracked_time_id_seq OWNER TO gitea_user;

--
-- Name: tracked_time_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.tracked_time_id_seq OWNED BY public.tracked_time.id;


--
-- Name: two_factor; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.two_factor (
    id bigint NOT NULL,
    uid bigint,
    secret character varying(255),
    scratch_salt character varying(255),
    scratch_hash character varying(255),
    last_used_passcode character varying(10),
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.two_factor OWNER TO gitea_user;

--
-- Name: two_factor_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.two_factor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.two_factor_id_seq OWNER TO gitea_user;

--
-- Name: two_factor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.two_factor_id_seq OWNED BY public.two_factor.id;


--
-- Name: upload; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.upload (
    id bigint NOT NULL,
    uuid uuid,
    name character varying(255)
);


ALTER TABLE public.upload OWNER TO gitea_user;

--
-- Name: upload_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.upload_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.upload_id_seq OWNER TO gitea_user;

--
-- Name: upload_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.upload_id_seq OWNED BY public.upload.id;


--
-- Name: user; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public."user" (
    id bigint NOT NULL,
    lower_name character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    full_name character varying(255),
    email character varying(255) NOT NULL,
    keep_email_private boolean,
    email_notifications_preference character varying(20) DEFAULT 'enabled'::character varying NOT NULL,
    passwd character varying(255) NOT NULL,
    passwd_hash_algo character varying(255) DEFAULT 'argon2'::character varying NOT NULL,
    must_change_password boolean DEFAULT false NOT NULL,
    login_type integer,
    login_source bigint DEFAULT 0 NOT NULL,
    login_name character varying(255),
    type integer,
    location character varying(255),
    website character varying(255),
    rands character varying(32),
    salt character varying(32),
    language character varying(5),
    description character varying(255),
    created_unix bigint,
    updated_unix bigint,
    last_login_unix bigint,
    last_repo_visibility boolean,
    max_repo_creation integer DEFAULT '-1'::integer NOT NULL,
    is_active boolean,
    is_admin boolean,
    is_restricted boolean DEFAULT false NOT NULL,
    allow_git_hook boolean,
    allow_import_local boolean,
    allow_create_organization boolean DEFAULT true,
    prohibit_login boolean DEFAULT false NOT NULL,
    avatar character varying(2048) NOT NULL,
    avatar_email character varying(255) NOT NULL,
    use_custom_avatar boolean,
    num_followers integer,
    num_following integer DEFAULT 0 NOT NULL,
    num_stars integer,
    num_repos integer,
    num_teams integer,
    num_members integer,
    visibility integer DEFAULT 0 NOT NULL,
    repo_admin_change_team_access boolean DEFAULT false NOT NULL,
    diff_view_style character varying(255) DEFAULT ''::character varying NOT NULL,
    theme character varying(255) DEFAULT ''::character varying NOT NULL,
    keep_activity_private boolean DEFAULT false NOT NULL
);


ALTER TABLE public."user" OWNER TO gitea_user;

--
-- Name: user_badge; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.user_badge (
    id bigint NOT NULL,
    badge_id bigint,
    user_id bigint
);


ALTER TABLE public.user_badge OWNER TO gitea_user;

--
-- Name: user_badge_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.user_badge_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_badge_id_seq OWNER TO gitea_user;

--
-- Name: user_badge_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.user_badge_id_seq OWNED BY public.user_badge.id;


--
-- Name: user_blocking; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.user_blocking (
    id bigint NOT NULL,
    blocker_id bigint,
    blockee_id bigint,
    note character varying(255),
    created_unix bigint
);


ALTER TABLE public.user_blocking OWNER TO gitea_user;

--
-- Name: user_blocking_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.user_blocking_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_blocking_id_seq OWNER TO gitea_user;

--
-- Name: user_blocking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.user_blocking_id_seq OWNED BY public.user_blocking.id;


--
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_id_seq OWNER TO gitea_user;

--
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.user_id_seq OWNED BY public."user".id;


--
-- Name: user_open_id; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.user_open_id (
    id bigint NOT NULL,
    uid bigint NOT NULL,
    uri character varying(255) NOT NULL,
    show boolean DEFAULT false
);


ALTER TABLE public.user_open_id OWNER TO gitea_user;

--
-- Name: user_open_id_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.user_open_id_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_open_id_id_seq OWNER TO gitea_user;

--
-- Name: user_open_id_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.user_open_id_id_seq OWNED BY public.user_open_id.id;


--
-- Name: user_redirect; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.user_redirect (
    id bigint NOT NULL,
    lower_name character varying(255) NOT NULL,
    redirect_user_id bigint
);


ALTER TABLE public.user_redirect OWNER TO gitea_user;

--
-- Name: user_redirect_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.user_redirect_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_redirect_id_seq OWNER TO gitea_user;

--
-- Name: user_redirect_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.user_redirect_id_seq OWNED BY public.user_redirect.id;


--
-- Name: user_setting; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.user_setting (
    id bigint NOT NULL,
    user_id bigint,
    setting_key character varying(255),
    setting_value text
);


ALTER TABLE public.user_setting OWNER TO gitea_user;

--
-- Name: user_setting_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.user_setting_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_setting_id_seq OWNER TO gitea_user;

--
-- Name: user_setting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.user_setting_id_seq OWNED BY public.user_setting.id;


--
-- Name: version; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.version (
    id bigint NOT NULL,
    version bigint
);


ALTER TABLE public.version OWNER TO gitea_user;

--
-- Name: version_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.version_id_seq OWNER TO gitea_user;

--
-- Name: version_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.version_id_seq OWNED BY public.version.id;


--
-- Name: watch; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.watch (
    id bigint NOT NULL,
    user_id bigint,
    repo_id bigint,
    mode smallint DEFAULT 1 NOT NULL,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.watch OWNER TO gitea_user;

--
-- Name: watch_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.watch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.watch_id_seq OWNER TO gitea_user;

--
-- Name: watch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.watch_id_seq OWNED BY public.watch.id;


--
-- Name: webauthn_credential; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.webauthn_credential (
    id bigint NOT NULL,
    name character varying(255),
    lower_name character varying(255),
    user_id bigint,
    credential_id bytea,
    public_key bytea,
    attestation_type character varying(255),
    aaguid bytea,
    sign_count bigint,
    clone_warning boolean,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.webauthn_credential OWNER TO gitea_user;

--
-- Name: webauthn_credential_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.webauthn_credential_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.webauthn_credential_id_seq OWNER TO gitea_user;

--
-- Name: webauthn_credential_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.webauthn_credential_id_seq OWNED BY public.webauthn_credential.id;


--
-- Name: webhook; Type: TABLE; Schema: public; Owner: gitea_user
--

CREATE TABLE public.webhook (
    id bigint NOT NULL,
    repo_id bigint,
    owner_id bigint,
    is_system_webhook boolean,
    url text,
    http_method character varying(255),
    content_type integer,
    secret text,
    events text,
    is_active boolean,
    type character varying(16),
    meta text,
    last_status integer,
    header_authorization_encrypted text,
    created_unix bigint,
    updated_unix bigint
);


ALTER TABLE public.webhook OWNER TO gitea_user;

--
-- Name: webhook_id_seq; Type: SEQUENCE; Schema: public; Owner: gitea_user
--

CREATE SEQUENCE public.webhook_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.webhook_id_seq OWNER TO gitea_user;

--
-- Name: webhook_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gitea_user
--

ALTER SEQUENCE public.webhook_id_seq OWNED BY public.webhook.id;


--
-- Name: access id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.access ALTER COLUMN id SET DEFAULT nextval('public.access_id_seq'::regclass);


--
-- Name: access_token id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.access_token ALTER COLUMN id SET DEFAULT nextval('public.access_token_id_seq'::regclass);


--
-- Name: action id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action ALTER COLUMN id SET DEFAULT nextval('public.action_id_seq'::regclass);


--
-- Name: action_artifact id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_artifact ALTER COLUMN id SET DEFAULT nextval('public.action_artifact_id_seq'::regclass);


--
-- Name: action_run id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_run ALTER COLUMN id SET DEFAULT nextval('public.action_run_id_seq'::regclass);


--
-- Name: action_run_job id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_run_job ALTER COLUMN id SET DEFAULT nextval('public.action_run_job_id_seq'::regclass);


--
-- Name: action_runner id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_runner ALTER COLUMN id SET DEFAULT nextval('public.action_runner_id_seq'::regclass);


--
-- Name: action_runner_token id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_runner_token ALTER COLUMN id SET DEFAULT nextval('public.action_runner_token_id_seq'::regclass);


--
-- Name: action_schedule id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_schedule ALTER COLUMN id SET DEFAULT nextval('public.action_schedule_id_seq'::regclass);


--
-- Name: action_schedule_spec id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_schedule_spec ALTER COLUMN id SET DEFAULT nextval('public.action_schedule_spec_id_seq'::regclass);


--
-- Name: action_task id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_task ALTER COLUMN id SET DEFAULT nextval('public.action_task_id_seq'::regclass);


--
-- Name: action_task_output id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_task_output ALTER COLUMN id SET DEFAULT nextval('public.action_task_output_id_seq'::regclass);


--
-- Name: action_task_step id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_task_step ALTER COLUMN id SET DEFAULT nextval('public.action_task_step_id_seq'::regclass);


--
-- Name: action_tasks_version id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_tasks_version ALTER COLUMN id SET DEFAULT nextval('public.action_tasks_version_id_seq'::regclass);


--
-- Name: action_variable id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_variable ALTER COLUMN id SET DEFAULT nextval('public.action_variable_id_seq'::regclass);


--
-- Name: attachment id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.attachment ALTER COLUMN id SET DEFAULT nextval('public.attachment_id_seq'::regclass);


--
-- Name: badge id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.badge ALTER COLUMN id SET DEFAULT nextval('public.badge_id_seq'::regclass);


--
-- Name: branch id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.branch ALTER COLUMN id SET DEFAULT nextval('public.branch_id_seq'::regclass);


--
-- Name: collaboration id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.collaboration ALTER COLUMN id SET DEFAULT nextval('public.collaboration_id_seq'::regclass);


--
-- Name: comment id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.comment ALTER COLUMN id SET DEFAULT nextval('public.comment_id_seq'::regclass);


--
-- Name: commit_status id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.commit_status ALTER COLUMN id SET DEFAULT nextval('public.commit_status_id_seq'::regclass);


--
-- Name: commit_status_index id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.commit_status_index ALTER COLUMN id SET DEFAULT nextval('public.commit_status_index_id_seq'::regclass);


--
-- Name: commit_status_summary id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.commit_status_summary ALTER COLUMN id SET DEFAULT nextval('public.commit_status_summary_id_seq'::regclass);


--
-- Name: dbfs_data id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.dbfs_data ALTER COLUMN id SET DEFAULT nextval('public.dbfs_data_id_seq'::regclass);


--
-- Name: dbfs_meta id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.dbfs_meta ALTER COLUMN id SET DEFAULT nextval('public.dbfs_meta_id_seq'::regclass);


--
-- Name: deploy_key id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.deploy_key ALTER COLUMN id SET DEFAULT nextval('public.deploy_key_id_seq'::regclass);


--
-- Name: email_address id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.email_address ALTER COLUMN id SET DEFAULT nextval('public.email_address_id_seq'::regclass);


--
-- Name: follow id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.follow ALTER COLUMN id SET DEFAULT nextval('public.follow_id_seq'::regclass);


--
-- Name: gpg_key id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.gpg_key ALTER COLUMN id SET DEFAULT nextval('public.gpg_key_id_seq'::regclass);


--
-- Name: hook_task id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.hook_task ALTER COLUMN id SET DEFAULT nextval('public.hook_task_id_seq'::regclass);


--
-- Name: issue id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue ALTER COLUMN id SET DEFAULT nextval('public.issue_id_seq'::regclass);


--
-- Name: issue_assignees id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue_assignees ALTER COLUMN id SET DEFAULT nextval('public.issue_assignees_id_seq'::regclass);


--
-- Name: issue_content_history id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue_content_history ALTER COLUMN id SET DEFAULT nextval('public.issue_content_history_id_seq'::regclass);


--
-- Name: issue_dependency id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue_dependency ALTER COLUMN id SET DEFAULT nextval('public.issue_dependency_id_seq'::regclass);


--
-- Name: issue_label id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue_label ALTER COLUMN id SET DEFAULT nextval('public.issue_label_id_seq'::regclass);


--
-- Name: issue_pin id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue_pin ALTER COLUMN id SET DEFAULT nextval('public.issue_pin_id_seq'::regclass);


--
-- Name: issue_user id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue_user ALTER COLUMN id SET DEFAULT nextval('public.issue_user_id_seq'::regclass);


--
-- Name: issue_watch id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue_watch ALTER COLUMN id SET DEFAULT nextval('public.issue_watch_id_seq'::regclass);


--
-- Name: label id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.label ALTER COLUMN id SET DEFAULT nextval('public.label_id_seq'::regclass);


--
-- Name: language_stat id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.language_stat ALTER COLUMN id SET DEFAULT nextval('public.language_stat_id_seq'::regclass);


--
-- Name: lfs_lock id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.lfs_lock ALTER COLUMN id SET DEFAULT nextval('public.lfs_lock_id_seq'::regclass);


--
-- Name: lfs_meta_object id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.lfs_meta_object ALTER COLUMN id SET DEFAULT nextval('public.lfs_meta_object_id_seq'::regclass);


--
-- Name: login_source id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.login_source ALTER COLUMN id SET DEFAULT nextval('public.login_source_id_seq'::regclass);


--
-- Name: milestone id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.milestone ALTER COLUMN id SET DEFAULT nextval('public.milestone_id_seq'::regclass);


--
-- Name: mirror id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.mirror ALTER COLUMN id SET DEFAULT nextval('public.mirror_id_seq'::regclass);


--
-- Name: notice id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.notice ALTER COLUMN id SET DEFAULT nextval('public.notice_id_seq'::regclass);


--
-- Name: notification id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.notification ALTER COLUMN id SET DEFAULT nextval('public.notification_id_seq'::regclass);


--
-- Name: oauth2_application id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.oauth2_application ALTER COLUMN id SET DEFAULT nextval('public.oauth2_application_id_seq'::regclass);


--
-- Name: oauth2_authorization_code id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.oauth2_authorization_code ALTER COLUMN id SET DEFAULT nextval('public.oauth2_authorization_code_id_seq'::regclass);


--
-- Name: oauth2_grant id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.oauth2_grant ALTER COLUMN id SET DEFAULT nextval('public.oauth2_grant_id_seq'::regclass);


--
-- Name: org_user id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.org_user ALTER COLUMN id SET DEFAULT nextval('public.org_user_id_seq'::regclass);


--
-- Name: package id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.package ALTER COLUMN id SET DEFAULT nextval('public.package_id_seq'::regclass);


--
-- Name: package_blob id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.package_blob ALTER COLUMN id SET DEFAULT nextval('public.package_blob_id_seq'::regclass);


--
-- Name: package_cleanup_rule id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.package_cleanup_rule ALTER COLUMN id SET DEFAULT nextval('public.package_cleanup_rule_id_seq'::regclass);


--
-- Name: package_file id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.package_file ALTER COLUMN id SET DEFAULT nextval('public.package_file_id_seq'::regclass);


--
-- Name: package_property id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.package_property ALTER COLUMN id SET DEFAULT nextval('public.package_property_id_seq'::regclass);


--
-- Name: package_version id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.package_version ALTER COLUMN id SET DEFAULT nextval('public.package_version_id_seq'::regclass);


--
-- Name: project id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.project ALTER COLUMN id SET DEFAULT nextval('public.project_id_seq'::regclass);


--
-- Name: project_board id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.project_board ALTER COLUMN id SET DEFAULT nextval('public.project_board_id_seq'::regclass);


--
-- Name: project_issue id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.project_issue ALTER COLUMN id SET DEFAULT nextval('public.project_issue_id_seq'::regclass);


--
-- Name: protected_branch id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.protected_branch ALTER COLUMN id SET DEFAULT nextval('public.protected_branch_id_seq'::regclass);


--
-- Name: protected_tag id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.protected_tag ALTER COLUMN id SET DEFAULT nextval('public.protected_tag_id_seq'::regclass);


--
-- Name: public_key id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.public_key ALTER COLUMN id SET DEFAULT nextval('public.public_key_id_seq'::regclass);


--
-- Name: pull_auto_merge id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.pull_auto_merge ALTER COLUMN id SET DEFAULT nextval('public.pull_auto_merge_id_seq'::regclass);


--
-- Name: pull_request id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.pull_request ALTER COLUMN id SET DEFAULT nextval('public.pull_request_id_seq'::regclass);


--
-- Name: push_mirror id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.push_mirror ALTER COLUMN id SET DEFAULT nextval('public.push_mirror_id_seq'::regclass);


--
-- Name: reaction id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.reaction ALTER COLUMN id SET DEFAULT nextval('public.reaction_id_seq'::regclass);


--
-- Name: release id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.release ALTER COLUMN id SET DEFAULT nextval('public.release_id_seq'::regclass);


--
-- Name: renamed_branch id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.renamed_branch ALTER COLUMN id SET DEFAULT nextval('public.renamed_branch_id_seq'::regclass);


--
-- Name: repo_archiver id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.repo_archiver ALTER COLUMN id SET DEFAULT nextval('public.repo_archiver_id_seq'::regclass);


--
-- Name: repo_indexer_status id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.repo_indexer_status ALTER COLUMN id SET DEFAULT nextval('public.repo_indexer_status_id_seq'::regclass);


--
-- Name: repo_license id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.repo_license ALTER COLUMN id SET DEFAULT nextval('public.repo_license_id_seq'::regclass);


--
-- Name: repo_redirect id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.repo_redirect ALTER COLUMN id SET DEFAULT nextval('public.repo_redirect_id_seq'::regclass);


--
-- Name: repo_transfer id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.repo_transfer ALTER COLUMN id SET DEFAULT nextval('public.repo_transfer_id_seq'::regclass);


--
-- Name: repo_unit id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.repo_unit ALTER COLUMN id SET DEFAULT nextval('public.repo_unit_id_seq'::regclass);


--
-- Name: repository id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.repository ALTER COLUMN id SET DEFAULT nextval('public.repository_id_seq'::regclass);


--
-- Name: review id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.review ALTER COLUMN id SET DEFAULT nextval('public.review_id_seq'::regclass);


--
-- Name: review_state id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.review_state ALTER COLUMN id SET DEFAULT nextval('public.review_state_id_seq'::regclass);


--
-- Name: secret id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.secret ALTER COLUMN id SET DEFAULT nextval('public.secret_id_seq'::regclass);


--
-- Name: star id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.star ALTER COLUMN id SET DEFAULT nextval('public.star_id_seq'::regclass);


--
-- Name: stopwatch id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.stopwatch ALTER COLUMN id SET DEFAULT nextval('public.stopwatch_id_seq'::regclass);


--
-- Name: system_setting id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.system_setting ALTER COLUMN id SET DEFAULT nextval('public.system_setting_id_seq'::regclass);


--
-- Name: task id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.task ALTER COLUMN id SET DEFAULT nextval('public.task_id_seq'::regclass);


--
-- Name: team id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.team ALTER COLUMN id SET DEFAULT nextval('public.team_id_seq'::regclass);


--
-- Name: team_invite id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.team_invite ALTER COLUMN id SET DEFAULT nextval('public.team_invite_id_seq'::regclass);


--
-- Name: team_repo id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.team_repo ALTER COLUMN id SET DEFAULT nextval('public.team_repo_id_seq'::regclass);


--
-- Name: team_unit id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.team_unit ALTER COLUMN id SET DEFAULT nextval('public.team_unit_id_seq'::regclass);


--
-- Name: team_user id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.team_user ALTER COLUMN id SET DEFAULT nextval('public.team_user_id_seq'::regclass);


--
-- Name: topic id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.topic ALTER COLUMN id SET DEFAULT nextval('public.topic_id_seq'::regclass);


--
-- Name: tracked_time id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.tracked_time ALTER COLUMN id SET DEFAULT nextval('public.tracked_time_id_seq'::regclass);


--
-- Name: two_factor id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.two_factor ALTER COLUMN id SET DEFAULT nextval('public.two_factor_id_seq'::regclass);


--
-- Name: upload id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.upload ALTER COLUMN id SET DEFAULT nextval('public.upload_id_seq'::regclass);


--
-- Name: user id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public."user" ALTER COLUMN id SET DEFAULT nextval('public.user_id_seq'::regclass);


--
-- Name: user_badge id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.user_badge ALTER COLUMN id SET DEFAULT nextval('public.user_badge_id_seq'::regclass);


--
-- Name: user_blocking id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.user_blocking ALTER COLUMN id SET DEFAULT nextval('public.user_blocking_id_seq'::regclass);


--
-- Name: user_open_id id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.user_open_id ALTER COLUMN id SET DEFAULT nextval('public.user_open_id_id_seq'::regclass);


--
-- Name: user_redirect id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.user_redirect ALTER COLUMN id SET DEFAULT nextval('public.user_redirect_id_seq'::regclass);


--
-- Name: user_setting id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.user_setting ALTER COLUMN id SET DEFAULT nextval('public.user_setting_id_seq'::regclass);


--
-- Name: version id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.version ALTER COLUMN id SET DEFAULT nextval('public.version_id_seq'::regclass);


--
-- Name: watch id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.watch ALTER COLUMN id SET DEFAULT nextval('public.watch_id_seq'::regclass);


--
-- Name: webauthn_credential id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.webauthn_credential ALTER COLUMN id SET DEFAULT nextval('public.webauthn_credential_id_seq'::regclass);


--
-- Name: webhook id; Type: DEFAULT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.webhook ALTER COLUMN id SET DEFAULT nextval('public.webhook_id_seq'::regclass);


--
-- Data for Name: access; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.access (id, user_id, repo_id, mode) FROM stdin;
1	1	3	4
2	1	4	4
3	1	5	4
4	1	6	4
\.


--
-- Data for Name: access_token; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.access_token (id, uid, name, token_hash, token_salt, token_last_eight, scope, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: action; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.action (id, user_id, op_type, act_user_id, repo_id, comment_id, is_deleted, ref_name, is_private, content, created_unix) FROM stdin;
1	3	1	3	1	0	f		f		1760052470
2	3	1	3	2	0	f		f		1760052471
3	1	1	1	3	0	f		f		1760052472
4	7	1	1	3	0	f		f		1760052472
5	1	1	1	4	0	f		f		1760052473
6	7	1	1	4	0	f		f		1760052473
7	1	1	1	5	0	f		f		1760052474
8	6	1	1	5	0	f		f		1760052474
9	1	1	1	6	0	f		f		1760052475
10	6	1	1	6	0	f		f		1760052475
11	2	1	2	7	0	f		f		1760052476
12	2	1	2	8	0	f		f		1760052477
13	4	1	4	9	0	f		f		1760052478
14	4	1	4	10	0	f		f		1760052479
\.


--
-- Data for Name: action_artifact; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.action_artifact (id, run_id, runner_id, repo_id, owner_id, commit_sha, storage_path, file_size, file_compressed_size, content_encoding, artifact_path, artifact_name, status, created_unix, updated_unix, expired_unix) FROM stdin;
\.


--
-- Data for Name: action_run; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.action_run (id, title, repo_id, owner_id, workflow_id, index, trigger_user_id, schedule_id, ref, commit_sha, is_fork_pull_request, need_approval, approved_by, event, event_payload, trigger_event, status, version, started, stopped, previous_duration, created, updated) FROM stdin;
\.


--
-- Data for Name: action_run_index; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.action_run_index (group_id, max_index) FROM stdin;
\.


--
-- Data for Name: action_run_job; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.action_run_job (id, run_id, repo_id, owner_id, commit_sha, is_fork_pull_request, name, attempt, workflow_payload, job_id, needs, runs_on, task_id, status, started, stopped, created, updated) FROM stdin;
\.


--
-- Data for Name: action_runner; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.action_runner (id, uuid, name, version, owner_id, repo_id, description, base, repo_range, token_hash, token_salt, last_online, last_active, agent_labels, ephemeral, created, updated, deleted) FROM stdin;
\.


--
-- Data for Name: action_runner_token; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.action_runner_token (id, token, owner_id, repo_id, is_active, created, updated, deleted) FROM stdin;
\.


--
-- Data for Name: action_schedule; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.action_schedule (id, title, specs, repo_id, owner_id, workflow_id, trigger_user_id, ref, commit_sha, event, event_payload, content, created, updated) FROM stdin;
\.


--
-- Data for Name: action_schedule_spec; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.action_schedule_spec (id, repo_id, schedule_id, next, prev, spec, created, updated) FROM stdin;
\.


--
-- Data for Name: action_task; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.action_task (id, job_id, attempt, runner_id, status, started, stopped, repo_id, owner_id, commit_sha, is_fork_pull_request, token_hash, token_salt, token_last_eight, log_filename, log_in_storage, log_length, log_size, log_indexes, log_expired, created, updated) FROM stdin;
\.


--
-- Data for Name: action_task_output; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.action_task_output (id, task_id, output_key, output_value) FROM stdin;
\.


--
-- Data for Name: action_task_step; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.action_task_step (id, name, task_id, index, repo_id, status, log_index, log_length, started, stopped, created, updated) FROM stdin;
\.


--
-- Data for Name: action_tasks_version; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.action_tasks_version (id, owner_id, repo_id, version, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: action_variable; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.action_variable (id, owner_id, repo_id, name, data, description, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: app_state; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.app_state (id, revision, content) FROM stdin;
runtime-state	0	{"last_app_path":"/usr/local/bin/gitea","last_custom_conf":"/data/gitea/conf/app.ini"}
\.


--
-- Data for Name: attachment; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.attachment (id, uuid, repo_id, issue_id, release_id, uploader_id, comment_id, name, download_count, size, created_unix) FROM stdin;
\.


--
-- Data for Name: auth_token; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.auth_token (id, token_hash, user_id, expires_unix) FROM stdin;
EGLeTvUnFo	ad90f245604fc22ebd3c72701e1a868080ac8b09519ae004ae53bd6f15a4412a	1	1762730861
\.


--
-- Data for Name: badge; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.badge (id, slug, description, image_url) FROM stdin;
\.


--
-- Data for Name: branch; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.branch (id, repo_id, name, commit_id, commit_message, pusher_id, is_deleted, deleted_by_id, deleted_unix, commit_time, created_unix, updated_unix) FROM stdin;
1	7	master	ee93f6be3e60b97c2447aa4f66966c88745affc2	Initial commit	0	f	0	0	1760051103	1760052490	1760052490
\.


--
-- Data for Name: collaboration; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.collaboration (id, repo_id, user_id, mode, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: comment; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.comment (id, type, poster_id, original_author, original_author_id, issue_id, label_id, old_project_id, project_id, old_milestone_id, milestone_id, time_id, assignee_id, removed_assignee, assignee_team_id, resolve_doer_id, old_title, new_title, old_ref, new_ref, dependent_issue_id, commit_id, line, tree_path, content, content_version, patch, created_unix, updated_unix, commit_sha, review_id, invalidated, ref_repo_id, ref_issue_id, ref_comment_id, ref_action, ref_is_pull, comment_meta_data) FROM stdin;
\.


--
-- Data for Name: commit_status; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.commit_status (id, index, repo_id, state, sha, target_url, description, context_hash, context, creator_id, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: commit_status_index; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.commit_status_index (id, repo_id, sha, max_index) FROM stdin;
\.


--
-- Data for Name: commit_status_summary; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.commit_status_summary (id, repo_id, sha, state, target_url) FROM stdin;
\.


--
-- Data for Name: dbfs_data; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.dbfs_data (id, revision, meta_id, blob_offset, blob_size, blob_data) FROM stdin;
\.


--
-- Data for Name: dbfs_meta; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.dbfs_meta (id, full_path, block_size, file_size, create_timestamp, modify_timestamp) FROM stdin;
\.


--
-- Data for Name: deploy_key; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.deploy_key (id, key_id, repo_id, name, fingerprint, mode, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: email_address; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.email_address (id, uid, email, lower_email, is_activated, is_primary) FROM stdin;
1	1	admin@gitea.zoo	admin@gitea.zoo	t	t
2	2	alice@gitea.zoo	alice@gitea.zoo	t	t
3	3	bob@gitea.zoo	bob@gitea.zoo	t	t
4	4	charlie@gitea.zoo	charlie@gitea.zoo	t	t
5	5	demo@gitea.zoo	demo@gitea.zoo	t	t
6	8	diana@gitea.zoo	diana@gitea.zoo	t	t
7	9	eve@gitea.zoo	eve@gitea.zoo	t	t
8	10	frank@gitea.zoo	frank@gitea.zoo	t	t
9	11	grace@gitea.zoo	grace@gitea.zoo	t	t
10	12	user1@gitea.zoo	user1@gitea.zoo	t	t
11	13	alex.chen@gitea.zoo	alex.chen@gitea.zoo	t	t
12	14	blake.sullivan@gitea.zoo	blake.sullivan@gitea.zoo	t	t
13	15	mallory@gitea.zoo	mallory@gitea.zoo	t	t
\.


--
-- Data for Name: email_hash; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.email_hash (hash, email) FROM stdin;
bec29e5174ebb72e6e40d26efdb85b23	bob@gitea.zoo
d8f0406e56d8133992149ac639e16ce2	alice@gitea.zoo
1268e0ec2c59848ba6157444a649a179	admin@gitea.zoo
6bb7aa663b279cd5ad1264aed62cf1dc	charlie@gitea.zoo
\.


--
-- Data for Name: external_login_user; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.external_login_user (external_id, user_id, login_source_id, raw_data, provider, email, name, first_name, last_name, nick_name, description, avatar_url, location, access_token, access_token_secret, refresh_token, expires_at) FROM stdin;
\.


--
-- Data for Name: follow; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.follow (id, user_id, follow_id, created_unix) FROM stdin;
\.


--
-- Data for Name: gpg_key; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.gpg_key (id, owner_id, key_id, primary_key_id, content, created_unix, expired_unix, added_unix, emails, verified, can_sign, can_encrypt_comms, can_encrypt_storage, can_certify) FROM stdin;
\.


--
-- Data for Name: gpg_key_import; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.gpg_key_import (key_id, content) FROM stdin;
\.


--
-- Data for Name: hook_task; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.hook_task (id, hook_id, uuid, payload_content, payload_version, event_type, is_delivered, delivered, is_succeed, request_content, response_content) FROM stdin;
\.


--
-- Data for Name: issue; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.issue (id, repo_id, index, poster_id, original_author, original_author_id, name, content, content_version, milestone_id, priority, is_closed, is_pull, num_comments, ref, deadline_unix, created_unix, updated_unix, closed_unix, is_locked, time_estimate) FROM stdin;
\.


--
-- Data for Name: issue_assignees; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.issue_assignees (id, assignee_id, issue_id) FROM stdin;
\.


--
-- Data for Name: issue_content_history; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.issue_content_history (id, poster_id, issue_id, comment_id, edited_unix, content_text, is_first_created, is_deleted) FROM stdin;
\.


--
-- Data for Name: issue_dependency; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.issue_dependency (id, user_id, issue_id, dependency_id, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: issue_index; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.issue_index (group_id, max_index) FROM stdin;
\.


--
-- Data for Name: issue_label; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.issue_label (id, issue_id, label_id) FROM stdin;
\.


--
-- Data for Name: issue_pin; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.issue_pin (id, repo_id, issue_id, is_pull, pin_order) FROM stdin;
\.


--
-- Data for Name: issue_user; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.issue_user (id, uid, issue_id, is_read, is_mentioned) FROM stdin;
\.


--
-- Data for Name: issue_watch; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.issue_watch (id, user_id, issue_id, is_watching, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: label; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.label (id, repo_id, org_id, name, exclusive, exclusive_order, description, color, num_issues, num_closed_issues, created_unix, updated_unix, archived_unix) FROM stdin;
\.


--
-- Data for Name: language_stat; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.language_stat (id, repo_id, commit_id, is_primary, language, size, created_unix) FROM stdin;
\.


--
-- Data for Name: lfs_lock; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.lfs_lock (id, repo_id, owner_id, path, created) FROM stdin;
\.


--
-- Data for Name: lfs_meta_object; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.lfs_meta_object (id, oid, size, repository_id, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: login_source; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.login_source (id, type, name, is_active, is_sync_enabled, two_factor_policy, cfg, created_unix, updated_unix) FROM stdin;
1	6	auth.zoo	t	f		{"Provider":"openidConnect","ClientID":"gitea","ClientSecret":"gitea-oauth-secret","OpenIDConnectAutoDiscoveryURL":"http://auth.zoo/.well-known/openid-configuration","CustomURLMapping":{},"IconURL":"","Scopes":null,"RequiredClaimName":"","RequiredClaimValue":"","GroupClaimName":"","AdminGroup":"","GroupTeamMap":"","GroupTeamMapRemoval":false,"RestrictedGroup":""}	1760052469	1760052469
\.


--
-- Data for Name: milestone; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.milestone (id, repo_id, name, content, is_closed, num_issues, num_closed_issues, completeness, created_unix, updated_unix, deadline_unix, closed_date_unix) FROM stdin;
\.


--
-- Data for Name: mirror; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.mirror (id, repo_id, "interval", enable_prune, updated_unix, next_update_unix, lfs_enabled, lfs_endpoint, remote_address) FROM stdin;
\.


--
-- Data for Name: notice; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.notice (id, type, description, created_unix) FROM stdin;
\.


--
-- Data for Name: notification; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.notification (id, user_id, repo_id, status, source, issue_id, commit_id, comment_id, updated_by, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: oauth2_application; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.oauth2_application (id, uid, name, client_id, client_secret, confidential_client, skip_secondary_authorization, redirect_uris, created_unix, updated_unix) FROM stdin;
1	0	git-credential-oauth	a4792ccc-144e-407e-86c9-5e7d8d9c3269		f	f	["http://127.0.0.1","https://127.0.0.1"]	1760052466	1760052466
2	0	Git Credential Manager	e90ee53c-94e2-48ac-9358-a874fb9e0662		f	f	["http://127.0.0.1","https://127.0.0.1"]	1760052466	1760052466
3	0	tea	d57cb8c4-630c-4168-8324-ec79935e18d4		f	f	["http://127.0.0.1","https://127.0.0.1"]	1760052466	1760052466
\.


--
-- Data for Name: oauth2_authorization_code; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.oauth2_authorization_code (id, grant_id, code, code_challenge, code_challenge_method, redirect_uri, valid_until) FROM stdin;
\.


--
-- Data for Name: oauth2_grant; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.oauth2_grant (id, user_id, application_id, counter, scope, nonce, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: org_user; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.org_user (id, uid, org_id, is_public) FROM stdin;
1	1	6	f
2	1	7	f
3	2	6	f
4	3	6	f
5	4	7	f
\.


--
-- Data for Name: package; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.package (id, owner_id, repo_id, type, name, lower_name, semver_compatible, is_internal) FROM stdin;
\.


--
-- Data for Name: package_blob; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.package_blob (id, size, hash_md5, hash_sha1, hash_sha256, hash_sha512, created_unix) FROM stdin;
\.


--
-- Data for Name: package_blob_upload; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.package_blob_upload (id, bytes_received, hash_state_bytes, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: package_cleanup_rule; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.package_cleanup_rule (id, enabled, owner_id, type, keep_count, keep_pattern, remove_days, remove_pattern, match_full_name, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: package_file; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.package_file (id, version_id, blob_id, name, lower_name, composite_key, is_lead, created_unix) FROM stdin;
\.


--
-- Data for Name: package_property; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.package_property (id, ref_type, ref_id, name, value) FROM stdin;
\.


--
-- Data for Name: package_version; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.package_version (id, package_id, creator_id, version, lower_version, created_unix, is_internal, metadata_json, download_count) FROM stdin;
\.


--
-- Data for Name: project; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.project (id, title, description, owner_id, repo_id, creator_id, is_closed, board_type, card_type, type, created_unix, updated_unix, closed_date_unix) FROM stdin;
\.


--
-- Data for Name: project_board; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.project_board (id, title, "default", sorting, color, project_id, creator_id, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: project_issue; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.project_issue (id, issue_id, project_id, project_board_id, sorting) FROM stdin;
\.


--
-- Data for Name: protected_branch; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.protected_branch (id, repo_id, branch_name, priority, can_push, enable_whitelist, whitelist_user_i_ds, whitelist_team_i_ds, enable_merge_whitelist, whitelist_deploy_keys, merge_whitelist_user_i_ds, merge_whitelist_team_i_ds, can_force_push, enable_force_push_allowlist, force_push_allowlist_user_i_ds, force_push_allowlist_team_i_ds, force_push_allowlist_deploy_keys, enable_status_check, status_check_contexts, enable_approvals_whitelist, approvals_whitelist_user_i_ds, approvals_whitelist_team_i_ds, required_approvals, block_on_rejected_reviews, block_on_official_review_requests, block_on_outdated_branch, dismiss_stale_approvals, ignore_stale_approvals, require_signed_commits, protected_file_patterns, unprotected_file_patterns, block_admin_merge_override, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: protected_tag; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.protected_tag (id, repo_id, name_pattern, allowlist_user_i_ds, allowlist_team_i_ds, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: public_key; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.public_key (id, owner_id, name, fingerprint, content, mode, type, login_source_id, created_unix, updated_unix, verified) FROM stdin;
\.


--
-- Data for Name: pull_auto_merge; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.pull_auto_merge (id, pull_id, doer_id, merge_style, message, delete_branch_after_merge, created_unix) FROM stdin;
\.


--
-- Data for Name: pull_request; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.pull_request (id, type, status, conflicted_files, commits_ahead, commits_behind, changed_protected_files, issue_id, index, head_repo_id, base_repo_id, head_branch, base_branch, merge_base, allow_maintainer_edit, has_merged, merged_commit_id, merger_id, merged_unix, flow) FROM stdin;
\.


--
-- Data for Name: push_mirror; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.push_mirror (id, repo_id, remote_name, remote_address, sync_on_commit, "interval", created_unix, last_update, last_error) FROM stdin;
\.


--
-- Data for Name: reaction; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.reaction (id, type, issue_id, comment_id, user_id, original_author_id, original_author, created_unix) FROM stdin;
\.


--
-- Data for Name: release; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.release (id, repo_id, publisher_id, tag_name, original_author, original_author_id, lower_tag_name, target, title, sha1, num_commits, note, is_draft, is_prerelease, is_tag, created_unix) FROM stdin;
\.


--
-- Data for Name: renamed_branch; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.renamed_branch (id, repo_id, "from", "to", created_unix) FROM stdin;
\.


--
-- Data for Name: repo_archiver; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.repo_archiver (id, repo_id, type, status, commit_id, created_unix) FROM stdin;
\.


--
-- Data for Name: repo_indexer_status; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.repo_indexer_status (id, repo_id, commit_sha, indexer_type) FROM stdin;
\.


--
-- Data for Name: repo_license; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.repo_license (id, repo_id, commit_id, license, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: repo_redirect; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.repo_redirect (id, owner_id, lower_name, redirect_repo_id) FROM stdin;
\.


--
-- Data for Name: repo_topic; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.repo_topic (repo_id, topic_id) FROM stdin;
\.


--
-- Data for Name: repo_transfer; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.repo_transfer (id, doer_id, recipient_id, repo_id, team_i_ds, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: repo_unit; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.repo_unit (id, repo_id, type, config, created_unix, anonymous_access_mode, everyone_access_mode) FROM stdin;
1	1	1	\N	1760052470	0	0
2	1	2	{"EnableTimetracker":true,"AllowOnlyContributorsToTrackTime":true,"EnableDependencies":true}	1760052470	0	0
3	1	3	{"IgnoreWhitespaceConflicts":false,"AllowMerge":true,"AllowRebase":true,"AllowRebaseMerge":true,"AllowSquash":true,"AllowFastForwardOnly":true,"AllowManualMerge":false,"AutodetectManualMerge":false,"AllowRebaseUpdate":true,"DefaultDeleteBranchAfterMerge":false,"DefaultMergeStyle":"merge","DefaultAllowMaintainerEdit":false}	1760052470	0	0
4	1	4	\N	1760052470	0	0
5	1	5	\N	1760052470	0	0
6	1	8	{"ProjectsMode":"all"}	1760052470	0	0
7	1	9	\N	1760052470	0	0
8	1	10	\N	1760052470	0	0
9	2	1	\N	1760052471	0	0
10	2	2	{"EnableTimetracker":true,"AllowOnlyContributorsToTrackTime":true,"EnableDependencies":true}	1760052471	0	0
11	2	3	{"IgnoreWhitespaceConflicts":false,"AllowMerge":true,"AllowRebase":true,"AllowRebaseMerge":true,"AllowSquash":true,"AllowFastForwardOnly":true,"AllowManualMerge":false,"AutodetectManualMerge":false,"AllowRebaseUpdate":true,"DefaultDeleteBranchAfterMerge":false,"DefaultMergeStyle":"merge","DefaultAllowMaintainerEdit":false}	1760052471	0	0
12	2	4	\N	1760052471	0	0
13	2	5	\N	1760052471	0	0
14	2	8	{"ProjectsMode":"all"}	1760052471	0	0
15	2	9	\N	1760052471	0	0
16	2	10	\N	1760052471	0	0
17	3	1	\N	1760052472	0	0
18	3	2	{"EnableTimetracker":true,"AllowOnlyContributorsToTrackTime":true,"EnableDependencies":true}	1760052472	0	0
19	3	3	{"IgnoreWhitespaceConflicts":false,"AllowMerge":true,"AllowRebase":true,"AllowRebaseMerge":true,"AllowSquash":true,"AllowFastForwardOnly":true,"AllowManualMerge":false,"AutodetectManualMerge":false,"AllowRebaseUpdate":true,"DefaultDeleteBranchAfterMerge":false,"DefaultMergeStyle":"merge","DefaultAllowMaintainerEdit":false}	1760052472	0	0
20	3	4	\N	1760052472	0	0
21	3	5	\N	1760052472	0	0
22	3	8	{"ProjectsMode":"all"}	1760052472	0	0
23	3	9	\N	1760052472	0	0
24	3	10	\N	1760052472	0	0
25	4	1	\N	1760052473	0	0
26	4	2	{"EnableTimetracker":true,"AllowOnlyContributorsToTrackTime":true,"EnableDependencies":true}	1760052473	0	0
27	4	3	{"IgnoreWhitespaceConflicts":false,"AllowMerge":true,"AllowRebase":true,"AllowRebaseMerge":true,"AllowSquash":true,"AllowFastForwardOnly":true,"AllowManualMerge":false,"AutodetectManualMerge":false,"AllowRebaseUpdate":true,"DefaultDeleteBranchAfterMerge":false,"DefaultMergeStyle":"merge","DefaultAllowMaintainerEdit":false}	1760052473	0	0
28	4	4	\N	1760052473	0	0
29	4	5	\N	1760052473	0	0
30	4	8	{"ProjectsMode":"all"}	1760052473	0	0
31	4	9	\N	1760052473	0	0
32	4	10	\N	1760052473	0	0
33	5	1	\N	1760052474	0	0
34	5	2	{"EnableTimetracker":true,"AllowOnlyContributorsToTrackTime":true,"EnableDependencies":true}	1760052474	0	0
35	5	3	{"IgnoreWhitespaceConflicts":false,"AllowMerge":true,"AllowRebase":true,"AllowRebaseMerge":true,"AllowSquash":true,"AllowFastForwardOnly":true,"AllowManualMerge":false,"AutodetectManualMerge":false,"AllowRebaseUpdate":true,"DefaultDeleteBranchAfterMerge":false,"DefaultMergeStyle":"merge","DefaultAllowMaintainerEdit":false}	1760052474	0	0
36	5	4	\N	1760052474	0	0
37	5	5	\N	1760052474	0	0
38	5	8	{"ProjectsMode":"all"}	1760052474	0	0
39	5	9	\N	1760052474	0	0
40	5	10	\N	1760052474	0	0
41	6	1	\N	1760052475	0	0
42	6	2	{"EnableTimetracker":true,"AllowOnlyContributorsToTrackTime":true,"EnableDependencies":true}	1760052475	0	0
43	6	3	{"IgnoreWhitespaceConflicts":false,"AllowMerge":true,"AllowRebase":true,"AllowRebaseMerge":true,"AllowSquash":true,"AllowFastForwardOnly":true,"AllowManualMerge":false,"AutodetectManualMerge":false,"AllowRebaseUpdate":true,"DefaultDeleteBranchAfterMerge":false,"DefaultMergeStyle":"merge","DefaultAllowMaintainerEdit":false}	1760052475	0	0
44	6	4	\N	1760052475	0	0
45	6	5	\N	1760052475	0	0
46	6	8	{"ProjectsMode":"all"}	1760052475	0	0
47	6	9	\N	1760052475	0	0
48	6	10	\N	1760052475	0	0
49	7	1	\N	1760052476	0	0
50	7	2	{"EnableTimetracker":true,"AllowOnlyContributorsToTrackTime":true,"EnableDependencies":true}	1760052476	0	0
51	7	3	{"IgnoreWhitespaceConflicts":false,"AllowMerge":true,"AllowRebase":true,"AllowRebaseMerge":true,"AllowSquash":true,"AllowFastForwardOnly":true,"AllowManualMerge":false,"AutodetectManualMerge":false,"AllowRebaseUpdate":true,"DefaultDeleteBranchAfterMerge":false,"DefaultMergeStyle":"merge","DefaultAllowMaintainerEdit":false}	1760052476	0	0
52	7	4	\N	1760052476	0	0
53	7	5	\N	1760052476	0	0
54	7	8	{"ProjectsMode":"all"}	1760052476	0	0
55	7	9	\N	1760052476	0	0
56	7	10	\N	1760052476	0	0
57	8	1	\N	1760052477	0	0
58	8	2	{"EnableTimetracker":true,"AllowOnlyContributorsToTrackTime":true,"EnableDependencies":true}	1760052477	0	0
59	8	3	{"IgnoreWhitespaceConflicts":false,"AllowMerge":true,"AllowRebase":true,"AllowRebaseMerge":true,"AllowSquash":true,"AllowFastForwardOnly":true,"AllowManualMerge":false,"AutodetectManualMerge":false,"AllowRebaseUpdate":true,"DefaultDeleteBranchAfterMerge":false,"DefaultMergeStyle":"merge","DefaultAllowMaintainerEdit":false}	1760052477	0	0
60	8	4	\N	1760052477	0	0
61	8	5	\N	1760052477	0	0
62	8	8	{"ProjectsMode":"all"}	1760052477	0	0
63	8	9	\N	1760052477	0	0
64	8	10	\N	1760052477	0	0
65	9	1	\N	1760052478	0	0
66	9	2	{"EnableTimetracker":true,"AllowOnlyContributorsToTrackTime":true,"EnableDependencies":true}	1760052478	0	0
67	9	3	{"IgnoreWhitespaceConflicts":false,"AllowMerge":true,"AllowRebase":true,"AllowRebaseMerge":true,"AllowSquash":true,"AllowFastForwardOnly":true,"AllowManualMerge":false,"AutodetectManualMerge":false,"AllowRebaseUpdate":true,"DefaultDeleteBranchAfterMerge":false,"DefaultMergeStyle":"merge","DefaultAllowMaintainerEdit":false}	1760052478	0	0
68	9	4	\N	1760052478	0	0
69	9	5	\N	1760052478	0	0
70	9	8	{"ProjectsMode":"all"}	1760052478	0	0
71	9	9	\N	1760052478	0	0
72	9	10	\N	1760052478	0	0
73	10	1	\N	1760052479	0	0
74	10	2	{"EnableTimetracker":true,"AllowOnlyContributorsToTrackTime":true,"EnableDependencies":true}	1760052479	0	0
75	10	3	{"IgnoreWhitespaceConflicts":false,"AllowMerge":true,"AllowRebase":true,"AllowRebaseMerge":true,"AllowSquash":true,"AllowFastForwardOnly":true,"AllowManualMerge":false,"AutodetectManualMerge":false,"AllowRebaseUpdate":true,"DefaultDeleteBranchAfterMerge":false,"DefaultMergeStyle":"merge","DefaultAllowMaintainerEdit":false}	1760052479	0	0
76	10	4	\N	1760052479	0	0
77	10	5	\N	1760052479	0	0
78	10	8	{"ProjectsMode":"all"}	1760052479	0	0
79	10	9	\N	1760052479	0	0
80	10	10	\N	1760052479	0	0
\.


--
-- Data for Name: repository; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.repository (id, owner_id, owner_name, lower_name, name, description, website, original_service_type, original_url, default_branch, default_wiki_branch, num_watches, num_stars, num_forks, num_issues, num_closed_issues, num_pulls, num_closed_pulls, num_milestones, num_closed_milestones, num_projects, num_closed_projects, num_action_runs, num_closed_action_runs, is_private, is_empty, is_archived, is_mirror, status, is_fork, fork_id, is_template, template_id, size, git_size, lfs_size, is_fsck_enabled, close_issues_via_commit_in_any_branch, topics, object_format_name, trust_model, avatar, created_unix, updated_unix, archived_unix) FROM stdin;
10	4	charlie	zoo-docker-templates	zoo-docker-templates	Docker templates for Zoo services		0		main	main	1	0	0	0	0	0	0	0	0	0	0	0	0	f	t	f	f	0	f	0	f	0	23147	23147	0	t	f	null	sha1	0		1760052479	1760052479	0
6	6	zoo-labs	zoo-utilities	zoo-utilities	Common utilities for Zoo applications		0		main	main	1	0	0	0	0	0	0	0	0	0	0	0	0	f	t	f	f	0	f	0	f	0	23147	23147	0	t	f	null	sha1	0		1760052475	1760052475	0
1	3	bob	zoo-api-client	zoo-api-client	API client library for Zoo services		0		main	main	1	0	0	0	0	0	0	0	0	0	0	0	0	f	t	f	f	0	f	0	f	0	23147	23147	0	t	f	null	sha1	0		1760052470	1760052470	0
2	3	bob	debug-mirror	debug-mirror			0		main	main	1	0	0	0	0	0	0	0	0	0	0	0	0	f	t	f	f	0	f	0	f	0	23147	23147	0	t	f	null	sha1	0		1760052471	1760052471	0
7	2	alice	hello-zoo	hello-zoo	A simple Hello World application for the Zoo		0		main	main	1	0	0	0	0	0	0	0	0	0	0	0	0	f	f	f	f	0	f	0	f	0	22456	22456	0	t	f	null	sha1	0		1760052476	1760052490	0
3	7	community	awesome-mirror	awesome-mirror			0		main	main	1	0	0	0	0	0	0	0	0	0	0	0	0	f	t	f	f	0	f	0	f	0	23147	23147	0	t	f	null	sha1	0		1760052472	1760052472	0
4	7	community	awesome-zoo	awesome-zoo	A curated list of awesome Zoo resources		0		main	main	1	0	0	0	0	0	0	0	0	0	0	0	0	f	t	f	f	0	f	0	f	0	23147	23147	0	t	f	null	sha1	0		1760052473	1760052473	0
8	2	alice	express-mirror	express-mirror			0		main	main	1	0	0	0	0	0	0	0	0	0	0	0	0	f	t	f	f	0	f	0	f	0	23147	23147	0	t	f	null	sha1	0		1760052477	1760052477	0
5	6	zoo-labs	commander-mirror	commander-mirror			0		main	main	1	0	0	0	0	0	0	0	0	0	0	0	0	f	t	f	f	0	f	0	f	0	23147	23147	0	t	f	null	sha1	0		1760052474	1760052474	0
9	4	charlie	realworld-mirror	realworld-mirror			0		main	main	1	0	0	0	0	0	0	0	0	0	0	0	0	f	t	f	f	0	f	0	f	0	23147	23147	0	t	f	null	sha1	0		1760052478	1760052478	0
\.


--
-- Data for Name: review; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.review (id, type, reviewer_id, reviewer_team_id, original_author, original_author_id, issue_id, content, official, commit_id, stale, dismissed, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: review_state; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.review_state (id, user_id, pull_id, commit_sha, updated_files, updated_unix) FROM stdin;
\.


--
-- Data for Name: secret; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.secret (id, owner_id, repo_id, name, data, description, created_unix) FROM stdin;
\.


--
-- Data for Name: session; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.session (key, data, expiry) FROM stdin;
\.


--
-- Data for Name: star; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.star (id, uid, repo_id, created_unix) FROM stdin;
\.


--
-- Data for Name: stopwatch; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.stopwatch (id, issue_id, user_id, created_unix) FROM stdin;
\.


--
-- Data for Name: system_setting; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.system_setting (id, setting_key, setting_value, version, created, updated) FROM stdin;
1	revision		2	1760052460	1760052460
2	picture.enable_federated_avatar	true	1	1760052460	1760052460
3	picture.disable_gravatar	false	1	1760052460	1760052460
\.


--
-- Data for Name: task; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.task (id, doer_id, owner_id, repo_id, type, status, start_time, end_time, payload_content, message, created) FROM stdin;
\.


--
-- Data for Name: team; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.team (id, org_id, lower_name, name, description, authorize, num_repos, num_members, includes_all_repositories, can_create_org_repo) FROM stdin;
2	7	owners	Owners		4	2	1	t	t
1	6	owners	Owners		4	2	1	t	t
3	6	developers	developers	Core development team	0	0	2	f	f
4	7	maintainers	maintainers	Community maintainers	3	0	1	f	f
\.


--
-- Data for Name: team_invite; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.team_invite (id, token, inviter_id, org_id, team_id, email, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: team_repo; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.team_repo (id, org_id, team_id, repo_id) FROM stdin;
1	7	2	3
2	7	2	4
3	6	1	5
4	6	1	6
\.


--
-- Data for Name: team_unit; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.team_unit (id, org_id, team_id, type, access_mode) FROM stdin;
1	6	1	1	4
2	6	1	2	4
3	6	1	3	4
4	6	1	4	4
5	6	1	5	4
6	6	1	6	1
7	6	1	7	1
8	6	1	8	4
9	6	1	9	4
10	6	1	10	4
11	7	2	1	4
12	7	2	2	4
13	7	2	3	4
14	7	2	4	4
15	7	2	5	4
16	7	2	6	1
17	7	2	7	1
18	7	2	8	4
19	7	2	9	4
20	7	2	10	4
21	6	3	1	2
22	6	3	2	2
23	6	3	3	2
24	6	3	5	2
25	7	4	1	3
26	7	4	2	3
27	7	4	3	3
28	7	4	4	3
29	7	4	5	3
30	7	4	6	1
31	7	4	7	1
32	7	4	8	3
33	7	4	9	3
34	7	4	10	3
\.


--
-- Data for Name: team_user; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.team_user (id, org_id, team_id, uid) FROM stdin;
1	6	1	1
2	7	2	1
3	6	3	2
4	6	3	3
5	7	4	4
\.


--
-- Data for Name: topic; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.topic (id, name, repo_count, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: tracked_time; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.tracked_time (id, issue_id, user_id, created_unix, "time", deleted) FROM stdin;
\.


--
-- Data for Name: two_factor; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.two_factor (id, uid, secret, scratch_salt, scratch_hash, last_used_passcode, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: upload; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.upload (id, uuid, name) FROM stdin;
\.


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public."user" (id, lower_name, name, full_name, email, keep_email_private, email_notifications_preference, passwd, passwd_hash_algo, must_change_password, login_type, login_source, login_name, type, location, website, rands, salt, language, description, created_unix, updated_unix, last_login_unix, last_repo_visibility, max_repo_creation, is_active, is_admin, is_restricted, allow_git_hook, allow_import_local, allow_create_organization, prohibit_login, avatar, avatar_email, use_custom_avatar, num_followers, num_following, num_stars, num_repos, num_teams, num_members, visibility, repo_admin_change_team_access, diff_view_style, theme, keep_activity_private) FROM stdin;
1	admin	admin		admin@gitea.zoo	f	enabled	b2a7771347462127d10f04d41813fbcd7745d99ade02727bdaefb39aa0352e74e5c9eb856bb3a8e961bf1d2eee2cfabb8a52	pbkdf2$50000$50	f	0	0		0			8e10acfdfcd4e1f2f8832e6b94715c27	904bb3030140817be4e881f39cb8a92f			1760052461	1760052461	0	f	-1	t	t	f	f	f	t	f		admin@gitea.zoo	f	0	0	0	0	0	0	0	f		gitea-auto	f
5	demo	demo		demo@gitea.zoo	f	enabled	8fef31d6b5ba543b57b86b43199f05afc241d42fb808989f195592ed7a922bf2c9cdd14d44a74a52a350c99e2f2c3243b16d	pbkdf2$50000$50	f	0	0		0			f2b5d014fc50a53e789dbcc273e50e90	db7b10b190092925424b1fa2cada2e3b			1760052470	1760052470	0	f	-1	t	f	f	f	f	t	f		demo@gitea.zoo	f	0	0	0	0	0	0	0	f		gitea-auto	f
6	zoo-labs	zoo-labs	Zoo Labs		f				f	0	0		1	The Zoo	http://zoo-labs.zoo	9898a272d908ee7ab32cdbf26f46e94a	34d6801083df0df55d45a233b0821949		Official Zoo development organization	1760052470	1760052475	0	f	-1	t	f	f	f	f	f	f	2a325b67141efec1d6a118589de543b8		t	0	0	0	2	2	3	0	f			f
3	bob	bob		bob@gitea.zoo	f	enabled	f1225b11bf6c28d6803c20e3f4f006d599e108c83d484defac20c3c6407c7901fddac7a8d23e5a7b8b77e7382c9323ea040e	pbkdf2$50000$50	f	0	0		0			2afbd482ee3589af33100f3af4a3c1bb	d63014e43071fea0a6f9dc6e1dafb182			1760052470	1760052471	0	f	-1	t	f	f	f	f	t	f		bob@gitea.zoo	f	0	0	0	2	0	0	0	f		gitea-auto	f
7	community	community	Zoo Community		f				f	0	0		1	The Zoo	http://community.zoo	d130e8a8c9050a5cd1e1509cda8399d1	35b08a9567cb12a7bf52a8b85d8ae6b2		Community-driven projects	1760052470	1760052473	0	f	-1	t	f	f	f	f	f	f	82df41632da476065ce2997900554442		t	0	0	0	2	2	2	0	f			f
2	alice	alice		alice@gitea.zoo	f	enabled	a1bb71da85ed441f141c00f5d256f846907fff9a33f0fbefea6dc058606a3de636d7a257f32bf1d068cd75b73f977c36bb42	pbkdf2$50000$50	f	0	0		0			d1021f83b6370e7fde4136106fdd2059	c5c3d535f87ae6389f237e5cbb984927	en-US		1760052470	1760052477	1760052470	f	-1	t	f	f	f	f	t	f		alice@gitea.zoo	f	0	0	0	2	0	0	0	f		gitea-auto	f
4	charlie	charlie		charlie@gitea.zoo	f	enabled	245734c4cfc1dfcb6537de67aa5ebcd3d1a625c1a4032c6dde33b359bac3b42dd15f53f747a82cd547fda01149c79c4bfdca	pbkdf2$50000$50	f	0	0		0			febb4f3bdce60e94af6097e9981b21fc	48ae2cc45d565f966928070bd7e8716c			1760052470	1760052479	0	f	-1	t	f	f	f	f	t	f		charlie@gitea.zoo	f	0	0	0	2	0	0	0	f		gitea-auto	f
8	diana	diana		diana@gitea.zoo	f	enabled	6ef1ad1b2b4a6d8bebfc308a7c39579a53b15a8b0c074d257801e4c5de954c2f30f3fc9b42b178b43476a453d942b4124696	pbkdf2$50000$50	f	0	0		0			ac8afb94bdb53f8307c7207480886dd5	5264c9a108c349019a9e1ce345643c96			1760067869	1760067869	0	f	-1	t	f	f	f	f	t	f		diana@gitea.zoo	f	0	0	0	0	0	0	0	f		gitea-auto	f
9	eve	eve		eve@gitea.zoo	f	enabled	ba3091149f19e36c2dd5bf98fa33e21c2654baf41a5e657ea9ff5da33d073874fbd235826c726e857e1f2c3f946f3daf6058	pbkdf2$50000$50	f	0	0		0			00617547754d609ad2106a5d2822a874	f4e7b798a07c96e66d0d41ce3349df05			1760067870	1760067870	0	f	-1	t	f	f	f	f	t	f		eve@gitea.zoo	f	0	0	0	0	0	0	0	f		gitea-auto	f
10	frank	frank		frank@gitea.zoo	f	enabled	4ef90087a10f53f205323edbd05ae14f48e0ad54090441fb19856b6b8b63afd6dfdd4567aa3bd4d80979bb4c1b06b292ca8c	pbkdf2$50000$50	f	0	0		0			5c554395ff8b6e561b45f97cc2f7a5b0	c3e1113b38b31e1707aaece65d4baaa5			1760067870	1760067870	0	f	-1	t	f	f	f	f	t	f		frank@gitea.zoo	f	0	0	0	0	0	0	0	f		gitea-auto	f
11	grace	grace		grace@gitea.zoo	f	enabled	3ac042f7cda49462a9c653b208577544f11cad76874271d1e1f486adcdc3438cfb4ccec96c10eebbae8910df5d84346b7dfc	pbkdf2$50000$50	f	0	0		0			8905f0d8c21343b756524086471e5de1	81055e3d9a3ccd63535bafc4923d901e			1760067870	1760067870	0	f	-1	t	f	f	f	f	t	f		grace@gitea.zoo	f	0	0	0	0	0	0	0	f		gitea-auto	f
12	user1	user1		user1@gitea.zoo	f	enabled	1923a24e32225433464c2e58c3a2d1d632901ec871010457545b3a85d31697960e5f0072f0e923e04ca64c987625ed6bf854	pbkdf2$50000$50	f	0	0		0			92263e8c9f7209fe127535d8bc99c491	d7d8494890f2e7ec254232543e5d6e97			1760067871	1760067871	0	f	-1	t	f	f	f	f	t	f		user1@gitea.zoo	f	0	0	0	0	0	0	0	f		gitea-auto	f
13	alex.chen	alex.chen		alex.chen@gitea.zoo	f	enabled	4abd446c0c8fd6b57d4b21c8c3ec8272a59e15ac08ef0c30b07909177891b2bf7e759d188f4d3fc2f1add8fa470c13b826bc	pbkdf2$50000$50	f	0	0		0			d2b7212d2b0ac257c48a6230614fe91b	b081a7708cac1fb4c81b1b2b6e6dbd74			1760067872	1760067872	0	f	-1	t	f	f	f	f	t	f		alex.chen@gitea.zoo	f	0	0	0	0	0	0	0	f		gitea-auto	f
14	blake.sullivan	blake.sullivan		blake.sullivan@gitea.zoo	f	enabled	a8cb5cd94032d2707c225e100b782d321d45d55321b1bf34dd200e7af9aca6a18c20bc684562f5baba16248bcfd2d86b80c8	pbkdf2$50000$50	f	0	0		0			c8a9ba42d7fbafb928052f94dfc7a2dd	7668005601d8dd6478a08b6c34551788			1760067872	1760067872	0	f	-1	t	f	f	f	f	t	f		blake.sullivan@gitea.zoo	f	0	0	0	0	0	0	0	f		gitea-auto	f
15	mallory	mallory		mallory@gitea.zoo	f	enabled	eea20e693341eb8b97cae19864d1f04121558f1a643eaa484399f10a88430138e4272cde0610cdfea22b47125f8969c9147f	pbkdf2$50000$50	f	0	0		0			3f0292eefbb7578eb8ffc0afc31ed66c	aebe0f35229f1b86a25752126a7f5f1a			1760067872	1760067872	0	f	-1	t	f	f	f	f	t	f		mallory@gitea.zoo	f	0	0	0	0	0	0	0	f		gitea-auto	f
\.


--
-- Data for Name: user_badge; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.user_badge (id, badge_id, user_id) FROM stdin;
\.


--
-- Data for Name: user_blocking; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.user_blocking (id, blocker_id, blockee_id, note, created_unix) FROM stdin;
\.


--
-- Data for Name: user_open_id; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.user_open_id (id, uid, uri, show) FROM stdin;
\.


--
-- Data for Name: user_redirect; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.user_redirect (id, lower_name, redirect_user_id) FROM stdin;
\.


--
-- Data for Name: user_setting; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.user_setting (id, user_id, setting_key, setting_value) FROM stdin;
\.


--
-- Data for Name: version; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.version (id, version) FROM stdin;
1	321
\.


--
-- Data for Name: watch; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.watch (id, user_id, repo_id, mode, created_unix, updated_unix) FROM stdin;
1	3	1	1	1760052470	1760052470
2	3	2	1	1760052471	1760052471
3	1	3	1	1760052472	1760052472
4	1	4	1	1760052473	1760052473
5	1	5	1	1760052474	1760052474
6	1	6	1	1760052475	1760052475
7	2	7	1	1760052476	1760052476
8	2	8	1	1760052477	1760052477
9	4	9	1	1760052478	1760052478
10	4	10	1	1760052479	1760052479
\.


--
-- Data for Name: webauthn_credential; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.webauthn_credential (id, name, lower_name, user_id, credential_id, public_key, attestation_type, aaguid, sign_count, clone_warning, created_unix, updated_unix) FROM stdin;
\.


--
-- Data for Name: webhook; Type: TABLE DATA; Schema: public; Owner: gitea_user
--

COPY public.webhook (id, repo_id, owner_id, is_system_webhook, url, http_method, content_type, secret, events, is_active, type, meta, last_status, header_authorization_encrypted, created_unix, updated_unix) FROM stdin;
\.


--
-- Name: access_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.access_id_seq', 4, true);


--
-- Name: access_token_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.access_token_id_seq', 1, false);


--
-- Name: action_artifact_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.action_artifact_id_seq', 1, false);


--
-- Name: action_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.action_id_seq', 14, true);


--
-- Name: action_run_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.action_run_id_seq', 1, false);


--
-- Name: action_run_job_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.action_run_job_id_seq', 1, false);


--
-- Name: action_runner_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.action_runner_id_seq', 1, false);


--
-- Name: action_runner_token_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.action_runner_token_id_seq', 1, false);


--
-- Name: action_schedule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.action_schedule_id_seq', 1, false);


--
-- Name: action_schedule_spec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.action_schedule_spec_id_seq', 1, false);


--
-- Name: action_task_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.action_task_id_seq', 1, false);


--
-- Name: action_task_output_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.action_task_output_id_seq', 1, false);


--
-- Name: action_task_step_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.action_task_step_id_seq', 1, false);


--
-- Name: action_tasks_version_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.action_tasks_version_id_seq', 1, false);


--
-- Name: action_variable_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.action_variable_id_seq', 1, false);


--
-- Name: attachment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.attachment_id_seq', 1, false);


--
-- Name: badge_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.badge_id_seq', 1, false);


--
-- Name: branch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.branch_id_seq', 1, true);


--
-- Name: collaboration_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.collaboration_id_seq', 1, false);


--
-- Name: comment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.comment_id_seq', 1, false);


--
-- Name: commit_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.commit_status_id_seq', 1, false);


--
-- Name: commit_status_index_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.commit_status_index_id_seq', 1, false);


--
-- Name: commit_status_summary_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.commit_status_summary_id_seq', 1, false);


--
-- Name: dbfs_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.dbfs_data_id_seq', 1, false);


--
-- Name: dbfs_meta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.dbfs_meta_id_seq', 1, false);


--
-- Name: deploy_key_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.deploy_key_id_seq', 1, false);


--
-- Name: email_address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.email_address_id_seq', 13, true);


--
-- Name: follow_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.follow_id_seq', 1, false);


--
-- Name: gpg_key_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.gpg_key_id_seq', 1, false);


--
-- Name: hook_task_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.hook_task_id_seq', 1, false);


--
-- Name: issue_assignees_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.issue_assignees_id_seq', 1, false);


--
-- Name: issue_content_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.issue_content_history_id_seq', 1, false);


--
-- Name: issue_dependency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.issue_dependency_id_seq', 1, false);


--
-- Name: issue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.issue_id_seq', 1, false);


--
-- Name: issue_label_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.issue_label_id_seq', 1, false);


--
-- Name: issue_pin_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.issue_pin_id_seq', 1, false);


--
-- Name: issue_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.issue_user_id_seq', 1, false);


--
-- Name: issue_watch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.issue_watch_id_seq', 1, false);


--
-- Name: label_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.label_id_seq', 1, false);


--
-- Name: language_stat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.language_stat_id_seq', 1, false);


--
-- Name: lfs_lock_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.lfs_lock_id_seq', 1, false);


--
-- Name: lfs_meta_object_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.lfs_meta_object_id_seq', 1, false);


--
-- Name: login_source_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.login_source_id_seq', 1, true);


--
-- Name: milestone_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.milestone_id_seq', 1, false);


--
-- Name: mirror_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.mirror_id_seq', 1, false);


--
-- Name: notice_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.notice_id_seq', 1, false);


--
-- Name: notification_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.notification_id_seq', 1, false);


--
-- Name: oauth2_application_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.oauth2_application_id_seq', 3, true);


--
-- Name: oauth2_authorization_code_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.oauth2_authorization_code_id_seq', 1, false);


--
-- Name: oauth2_grant_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.oauth2_grant_id_seq', 1, false);


--
-- Name: org_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.org_user_id_seq', 5, true);


--
-- Name: package_blob_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.package_blob_id_seq', 1, false);


--
-- Name: package_cleanup_rule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.package_cleanup_rule_id_seq', 1, false);


--
-- Name: package_file_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.package_file_id_seq', 1, false);


--
-- Name: package_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.package_id_seq', 1, false);


--
-- Name: package_property_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.package_property_id_seq', 1, false);


--
-- Name: package_version_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.package_version_id_seq', 1, false);


--
-- Name: project_board_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.project_board_id_seq', 1, false);


--
-- Name: project_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.project_id_seq', 1, false);


--
-- Name: project_issue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.project_issue_id_seq', 1, false);


--
-- Name: protected_branch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.protected_branch_id_seq', 1, false);


--
-- Name: protected_tag_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.protected_tag_id_seq', 1, false);


--
-- Name: public_key_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.public_key_id_seq', 1, false);


--
-- Name: pull_auto_merge_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.pull_auto_merge_id_seq', 1, false);


--
-- Name: pull_request_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.pull_request_id_seq', 1, false);


--
-- Name: push_mirror_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.push_mirror_id_seq', 1, false);


--
-- Name: reaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.reaction_id_seq', 1, false);


--
-- Name: release_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.release_id_seq', 1, false);


--
-- Name: renamed_branch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.renamed_branch_id_seq', 1, false);


--
-- Name: repo_archiver_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.repo_archiver_id_seq', 1, false);


--
-- Name: repo_indexer_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.repo_indexer_status_id_seq', 1, false);


--
-- Name: repo_license_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.repo_license_id_seq', 1, false);


--
-- Name: repo_redirect_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.repo_redirect_id_seq', 1, false);


--
-- Name: repo_transfer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.repo_transfer_id_seq', 1, false);


--
-- Name: repo_unit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.repo_unit_id_seq', 80, true);


--
-- Name: repository_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.repository_id_seq', 10, true);


--
-- Name: review_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.review_id_seq', 1, false);


--
-- Name: review_state_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.review_state_id_seq', 1, false);


--
-- Name: secret_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.secret_id_seq', 1, false);


--
-- Name: star_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.star_id_seq', 1, false);


--
-- Name: stopwatch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.stopwatch_id_seq', 1, false);


--
-- Name: system_setting_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.system_setting_id_seq', 3, true);


--
-- Name: task_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.task_id_seq', 1, false);


--
-- Name: team_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.team_id_seq', 4, true);


--
-- Name: team_invite_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.team_invite_id_seq', 1, false);


--
-- Name: team_repo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.team_repo_id_seq', 4, true);


--
-- Name: team_unit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.team_unit_id_seq', 34, true);


--
-- Name: team_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.team_user_id_seq', 5, true);


--
-- Name: topic_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.topic_id_seq', 1, false);


--
-- Name: tracked_time_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.tracked_time_id_seq', 1, false);


--
-- Name: two_factor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.two_factor_id_seq', 1, false);


--
-- Name: upload_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.upload_id_seq', 1, false);


--
-- Name: user_badge_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.user_badge_id_seq', 1, false);


--
-- Name: user_blocking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.user_blocking_id_seq', 1, false);


--
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.user_id_seq', 15, true);


--
-- Name: user_open_id_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.user_open_id_id_seq', 1, false);


--
-- Name: user_redirect_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.user_redirect_id_seq', 1, false);


--
-- Name: user_setting_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.user_setting_id_seq', 1, false);


--
-- Name: version_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.version_id_seq', 1, true);


--
-- Name: watch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.watch_id_seq', 10, true);


--
-- Name: webauthn_credential_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.webauthn_credential_id_seq', 1, false);


--
-- Name: webhook_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gitea_user
--

SELECT pg_catalog.setval('public.webhook_id_seq', 1, false);


--
-- Name: access access_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.access
    ADD CONSTRAINT access_pkey PRIMARY KEY (id);


--
-- Name: access_token access_token_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.access_token
    ADD CONSTRAINT access_token_pkey PRIMARY KEY (id);


--
-- Name: action_artifact action_artifact_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_artifact
    ADD CONSTRAINT action_artifact_pkey PRIMARY KEY (id);


--
-- Name: action action_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action
    ADD CONSTRAINT action_pkey PRIMARY KEY (id);


--
-- Name: action_run_index action_run_index_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_run_index
    ADD CONSTRAINT action_run_index_pkey PRIMARY KEY (group_id);


--
-- Name: action_run_job action_run_job_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_run_job
    ADD CONSTRAINT action_run_job_pkey PRIMARY KEY (id);


--
-- Name: action_run action_run_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_run
    ADD CONSTRAINT action_run_pkey PRIMARY KEY (id);


--
-- Name: action_runner action_runner_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_runner
    ADD CONSTRAINT action_runner_pkey PRIMARY KEY (id);


--
-- Name: action_runner_token action_runner_token_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_runner_token
    ADD CONSTRAINT action_runner_token_pkey PRIMARY KEY (id);


--
-- Name: action_schedule action_schedule_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_schedule
    ADD CONSTRAINT action_schedule_pkey PRIMARY KEY (id);


--
-- Name: action_schedule_spec action_schedule_spec_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_schedule_spec
    ADD CONSTRAINT action_schedule_spec_pkey PRIMARY KEY (id);


--
-- Name: action_task_output action_task_output_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_task_output
    ADD CONSTRAINT action_task_output_pkey PRIMARY KEY (id);


--
-- Name: action_task action_task_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_task
    ADD CONSTRAINT action_task_pkey PRIMARY KEY (id);


--
-- Name: action_task_step action_task_step_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_task_step
    ADD CONSTRAINT action_task_step_pkey PRIMARY KEY (id);


--
-- Name: action_tasks_version action_tasks_version_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_tasks_version
    ADD CONSTRAINT action_tasks_version_pkey PRIMARY KEY (id);


--
-- Name: action_variable action_variable_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.action_variable
    ADD CONSTRAINT action_variable_pkey PRIMARY KEY (id);


--
-- Name: app_state app_state_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.app_state
    ADD CONSTRAINT app_state_pkey PRIMARY KEY (id);


--
-- Name: attachment attachment_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.attachment
    ADD CONSTRAINT attachment_pkey PRIMARY KEY (id);


--
-- Name: auth_token auth_token_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.auth_token
    ADD CONSTRAINT auth_token_pkey PRIMARY KEY (id);


--
-- Name: badge badge_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.badge
    ADD CONSTRAINT badge_pkey PRIMARY KEY (id);


--
-- Name: branch branch_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.branch
    ADD CONSTRAINT branch_pkey PRIMARY KEY (id);


--
-- Name: collaboration collaboration_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.collaboration
    ADD CONSTRAINT collaboration_pkey PRIMARY KEY (id);


--
-- Name: comment comment_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT comment_pkey PRIMARY KEY (id);


--
-- Name: commit_status_index commit_status_index_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.commit_status_index
    ADD CONSTRAINT commit_status_index_pkey PRIMARY KEY (id);


--
-- Name: commit_status commit_status_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.commit_status
    ADD CONSTRAINT commit_status_pkey PRIMARY KEY (id);


--
-- Name: commit_status_summary commit_status_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.commit_status_summary
    ADD CONSTRAINT commit_status_summary_pkey PRIMARY KEY (id);


--
-- Name: dbfs_data dbfs_data_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.dbfs_data
    ADD CONSTRAINT dbfs_data_pkey PRIMARY KEY (id);


--
-- Name: dbfs_meta dbfs_meta_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.dbfs_meta
    ADD CONSTRAINT dbfs_meta_pkey PRIMARY KEY (id);


--
-- Name: deploy_key deploy_key_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.deploy_key
    ADD CONSTRAINT deploy_key_pkey PRIMARY KEY (id);


--
-- Name: email_address email_address_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.email_address
    ADD CONSTRAINT email_address_pkey PRIMARY KEY (id);


--
-- Name: email_hash email_hash_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.email_hash
    ADD CONSTRAINT email_hash_pkey PRIMARY KEY (hash);


--
-- Name: external_login_user external_login_user_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.external_login_user
    ADD CONSTRAINT external_login_user_pkey PRIMARY KEY (external_id, login_source_id);


--
-- Name: follow follow_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.follow
    ADD CONSTRAINT follow_pkey PRIMARY KEY (id);


--
-- Name: gpg_key_import gpg_key_import_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.gpg_key_import
    ADD CONSTRAINT gpg_key_import_pkey PRIMARY KEY (key_id);


--
-- Name: gpg_key gpg_key_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.gpg_key
    ADD CONSTRAINT gpg_key_pkey PRIMARY KEY (id);


--
-- Name: hook_task hook_task_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.hook_task
    ADD CONSTRAINT hook_task_pkey PRIMARY KEY (id);


--
-- Name: issue_assignees issue_assignees_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue_assignees
    ADD CONSTRAINT issue_assignees_pkey PRIMARY KEY (id);


--
-- Name: issue_content_history issue_content_history_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue_content_history
    ADD CONSTRAINT issue_content_history_pkey PRIMARY KEY (id);


--
-- Name: issue_dependency issue_dependency_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue_dependency
    ADD CONSTRAINT issue_dependency_pkey PRIMARY KEY (id);


--
-- Name: issue_index issue_index_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue_index
    ADD CONSTRAINT issue_index_pkey PRIMARY KEY (group_id);


--
-- Name: issue_label issue_label_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue_label
    ADD CONSTRAINT issue_label_pkey PRIMARY KEY (id);


--
-- Name: issue_pin issue_pin_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue_pin
    ADD CONSTRAINT issue_pin_pkey PRIMARY KEY (id);


--
-- Name: issue issue_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue
    ADD CONSTRAINT issue_pkey PRIMARY KEY (id);


--
-- Name: issue_user issue_user_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue_user
    ADD CONSTRAINT issue_user_pkey PRIMARY KEY (id);


--
-- Name: issue_watch issue_watch_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.issue_watch
    ADD CONSTRAINT issue_watch_pkey PRIMARY KEY (id);


--
-- Name: label label_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.label
    ADD CONSTRAINT label_pkey PRIMARY KEY (id);


--
-- Name: language_stat language_stat_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.language_stat
    ADD CONSTRAINT language_stat_pkey PRIMARY KEY (id);


--
-- Name: lfs_lock lfs_lock_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.lfs_lock
    ADD CONSTRAINT lfs_lock_pkey PRIMARY KEY (id);


--
-- Name: lfs_meta_object lfs_meta_object_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.lfs_meta_object
    ADD CONSTRAINT lfs_meta_object_pkey PRIMARY KEY (id);


--
-- Name: login_source login_source_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.login_source
    ADD CONSTRAINT login_source_pkey PRIMARY KEY (id);


--
-- Name: milestone milestone_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.milestone
    ADD CONSTRAINT milestone_pkey PRIMARY KEY (id);


--
-- Name: mirror mirror_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.mirror
    ADD CONSTRAINT mirror_pkey PRIMARY KEY (id);


--
-- Name: notice notice_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.notice
    ADD CONSTRAINT notice_pkey PRIMARY KEY (id);


--
-- Name: notification notification_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (id);


--
-- Name: oauth2_application oauth2_application_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.oauth2_application
    ADD CONSTRAINT oauth2_application_pkey PRIMARY KEY (id);


--
-- Name: oauth2_authorization_code oauth2_authorization_code_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.oauth2_authorization_code
    ADD CONSTRAINT oauth2_authorization_code_pkey PRIMARY KEY (id);


--
-- Name: oauth2_grant oauth2_grant_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.oauth2_grant
    ADD CONSTRAINT oauth2_grant_pkey PRIMARY KEY (id);


--
-- Name: org_user org_user_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.org_user
    ADD CONSTRAINT org_user_pkey PRIMARY KEY (id);


--
-- Name: package_blob package_blob_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.package_blob
    ADD CONSTRAINT package_blob_pkey PRIMARY KEY (id);


--
-- Name: package_blob_upload package_blob_upload_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.package_blob_upload
    ADD CONSTRAINT package_blob_upload_pkey PRIMARY KEY (id);


--
-- Name: package_cleanup_rule package_cleanup_rule_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.package_cleanup_rule
    ADD CONSTRAINT package_cleanup_rule_pkey PRIMARY KEY (id);


--
-- Name: package_file package_file_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.package_file
    ADD CONSTRAINT package_file_pkey PRIMARY KEY (id);


--
-- Name: package package_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.package
    ADD CONSTRAINT package_pkey PRIMARY KEY (id);


--
-- Name: package_property package_property_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.package_property
    ADD CONSTRAINT package_property_pkey PRIMARY KEY (id);


--
-- Name: package_version package_version_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.package_version
    ADD CONSTRAINT package_version_pkey PRIMARY KEY (id);


--
-- Name: project_board project_board_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.project_board
    ADD CONSTRAINT project_board_pkey PRIMARY KEY (id);


--
-- Name: project_issue project_issue_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.project_issue
    ADD CONSTRAINT project_issue_pkey PRIMARY KEY (id);


--
-- Name: project project_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.project
    ADD CONSTRAINT project_pkey PRIMARY KEY (id);


--
-- Name: protected_branch protected_branch_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.protected_branch
    ADD CONSTRAINT protected_branch_pkey PRIMARY KEY (id);


--
-- Name: protected_tag protected_tag_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.protected_tag
    ADD CONSTRAINT protected_tag_pkey PRIMARY KEY (id);


--
-- Name: public_key public_key_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.public_key
    ADD CONSTRAINT public_key_pkey PRIMARY KEY (id);


--
-- Name: pull_auto_merge pull_auto_merge_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.pull_auto_merge
    ADD CONSTRAINT pull_auto_merge_pkey PRIMARY KEY (id);


--
-- Name: pull_request pull_request_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.pull_request
    ADD CONSTRAINT pull_request_pkey PRIMARY KEY (id);


--
-- Name: push_mirror push_mirror_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.push_mirror
    ADD CONSTRAINT push_mirror_pkey PRIMARY KEY (id);


--
-- Name: reaction reaction_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.reaction
    ADD CONSTRAINT reaction_pkey PRIMARY KEY (id);


--
-- Name: release release_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.release
    ADD CONSTRAINT release_pkey PRIMARY KEY (id);


--
-- Name: renamed_branch renamed_branch_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.renamed_branch
    ADD CONSTRAINT renamed_branch_pkey PRIMARY KEY (id);


--
-- Name: repo_archiver repo_archiver_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.repo_archiver
    ADD CONSTRAINT repo_archiver_pkey PRIMARY KEY (id);


--
-- Name: repo_indexer_status repo_indexer_status_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.repo_indexer_status
    ADD CONSTRAINT repo_indexer_status_pkey PRIMARY KEY (id);


--
-- Name: repo_license repo_license_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.repo_license
    ADD CONSTRAINT repo_license_pkey PRIMARY KEY (id);


--
-- Name: repo_redirect repo_redirect_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.repo_redirect
    ADD CONSTRAINT repo_redirect_pkey PRIMARY KEY (id);


--
-- Name: repo_topic repo_topic_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.repo_topic
    ADD CONSTRAINT repo_topic_pkey PRIMARY KEY (repo_id, topic_id);


--
-- Name: repo_transfer repo_transfer_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.repo_transfer
    ADD CONSTRAINT repo_transfer_pkey PRIMARY KEY (id);


--
-- Name: repo_unit repo_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.repo_unit
    ADD CONSTRAINT repo_unit_pkey PRIMARY KEY (id);


--
-- Name: repository repository_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.repository
    ADD CONSTRAINT repository_pkey PRIMARY KEY (id);


--
-- Name: review review_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.review
    ADD CONSTRAINT review_pkey PRIMARY KEY (id);


--
-- Name: review_state review_state_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.review_state
    ADD CONSTRAINT review_state_pkey PRIMARY KEY (id);


--
-- Name: secret secret_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.secret
    ADD CONSTRAINT secret_pkey PRIMARY KEY (id);


--
-- Name: session session_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (key);


--
-- Name: star star_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.star
    ADD CONSTRAINT star_pkey PRIMARY KEY (id);


--
-- Name: stopwatch stopwatch_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.stopwatch
    ADD CONSTRAINT stopwatch_pkey PRIMARY KEY (id);


--
-- Name: system_setting system_setting_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.system_setting
    ADD CONSTRAINT system_setting_pkey PRIMARY KEY (id);


--
-- Name: task task_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.task
    ADD CONSTRAINT task_pkey PRIMARY KEY (id);


--
-- Name: team_invite team_invite_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.team_invite
    ADD CONSTRAINT team_invite_pkey PRIMARY KEY (id);


--
-- Name: team team_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.team
    ADD CONSTRAINT team_pkey PRIMARY KEY (id);


--
-- Name: team_repo team_repo_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.team_repo
    ADD CONSTRAINT team_repo_pkey PRIMARY KEY (id);


--
-- Name: team_unit team_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.team_unit
    ADD CONSTRAINT team_unit_pkey PRIMARY KEY (id);


--
-- Name: team_user team_user_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.team_user
    ADD CONSTRAINT team_user_pkey PRIMARY KEY (id);


--
-- Name: topic topic_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.topic
    ADD CONSTRAINT topic_pkey PRIMARY KEY (id);


--
-- Name: tracked_time tracked_time_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.tracked_time
    ADD CONSTRAINT tracked_time_pkey PRIMARY KEY (id);


--
-- Name: two_factor two_factor_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.two_factor
    ADD CONSTRAINT two_factor_pkey PRIMARY KEY (id);


--
-- Name: upload upload_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.upload
    ADD CONSTRAINT upload_pkey PRIMARY KEY (id);


--
-- Name: user_badge user_badge_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.user_badge
    ADD CONSTRAINT user_badge_pkey PRIMARY KEY (id);


--
-- Name: user_blocking user_blocking_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.user_blocking
    ADD CONSTRAINT user_blocking_pkey PRIMARY KEY (id);


--
-- Name: user_open_id user_open_id_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.user_open_id
    ADD CONSTRAINT user_open_id_pkey PRIMARY KEY (id);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: user_redirect user_redirect_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.user_redirect
    ADD CONSTRAINT user_redirect_pkey PRIMARY KEY (id);


--
-- Name: user_setting user_setting_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.user_setting
    ADD CONSTRAINT user_setting_pkey PRIMARY KEY (id);


--
-- Name: version version_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.version
    ADD CONSTRAINT version_pkey PRIMARY KEY (id);


--
-- Name: watch watch_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.watch
    ADD CONSTRAINT watch_pkey PRIMARY KEY (id);


--
-- Name: webauthn_credential webauthn_credential_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.webauthn_credential
    ADD CONSTRAINT webauthn_credential_pkey PRIMARY KEY (id);


--
-- Name: webhook webhook_pkey; Type: CONSTRAINT; Schema: public; Owner: gitea_user
--

ALTER TABLE ONLY public.webhook
    ADD CONSTRAINT webhook_pkey PRIMARY KEY (id);


--
-- Name: IDX_access_token_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_access_token_created_unix" ON public.access_token USING btree (created_unix);


--
-- Name: IDX_access_token_token_last_eight; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_access_token_token_last_eight" ON public.access_token USING btree (token_last_eight);


--
-- Name: IDX_access_token_uid; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_access_token_uid" ON public.access_token USING btree (uid);


--
-- Name: IDX_access_token_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_access_token_updated_unix" ON public.access_token USING btree (updated_unix);


--
-- Name: IDX_action_artifact_artifact_name; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_artifact_artifact_name" ON public.action_artifact USING btree (artifact_name);


--
-- Name: IDX_action_artifact_artifact_path; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_artifact_artifact_path" ON public.action_artifact USING btree (artifact_path);


--
-- Name: IDX_action_artifact_expired_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_artifact_expired_unix" ON public.action_artifact USING btree (expired_unix);


--
-- Name: IDX_action_artifact_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_artifact_repo_id" ON public.action_artifact USING btree (repo_id);


--
-- Name: IDX_action_artifact_run_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_artifact_run_id" ON public.action_artifact USING btree (run_id);


--
-- Name: IDX_action_artifact_status; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_artifact_status" ON public.action_artifact USING btree (status);


--
-- Name: IDX_action_artifact_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_artifact_updated_unix" ON public.action_artifact USING btree (updated_unix);


--
-- Name: IDX_action_au_c_u; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_au_c_u" ON public.action USING btree (act_user_id, created_unix, user_id);


--
-- Name: IDX_action_au_r_c_u_d; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_au_r_c_u_d" ON public.action USING btree (act_user_id, repo_id, created_unix, user_id, is_deleted);


--
-- Name: IDX_action_c_u; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_c_u" ON public.action USING btree (user_id, is_deleted);


--
-- Name: IDX_action_c_u_d; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_c_u_d" ON public.action USING btree (created_unix, user_id, is_deleted);


--
-- Name: IDX_action_comment_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_comment_id" ON public.action USING btree (comment_id);


--
-- Name: IDX_action_r_u_d; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_r_u_d" ON public.action USING btree (repo_id, user_id, is_deleted);


--
-- Name: IDX_action_run_approved_by; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_run_approved_by" ON public.action_run USING btree (approved_by);


--
-- Name: IDX_action_run_index; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_run_index" ON public.action_run USING btree (index);


--
-- Name: IDX_action_run_index_max_index; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_run_index_max_index" ON public.action_run_index USING btree (max_index);


--
-- Name: IDX_action_run_job_commit_sha; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_run_job_commit_sha" ON public.action_run_job USING btree (commit_sha);


--
-- Name: IDX_action_run_job_owner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_run_job_owner_id" ON public.action_run_job USING btree (owner_id);


--
-- Name: IDX_action_run_job_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_run_job_repo_id" ON public.action_run_job USING btree (repo_id);


--
-- Name: IDX_action_run_job_run_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_run_job_run_id" ON public.action_run_job USING btree (run_id);


--
-- Name: IDX_action_run_job_status; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_run_job_status" ON public.action_run_job USING btree (status);


--
-- Name: IDX_action_run_job_updated; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_run_job_updated" ON public.action_run_job USING btree (updated);


--
-- Name: IDX_action_run_owner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_run_owner_id" ON public.action_run USING btree (owner_id);


--
-- Name: IDX_action_run_ref; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_run_ref" ON public.action_run USING btree (ref);


--
-- Name: IDX_action_run_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_run_repo_id" ON public.action_run USING btree (repo_id);


--
-- Name: IDX_action_run_status; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_run_status" ON public.action_run USING btree (status);


--
-- Name: IDX_action_run_trigger_user_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_run_trigger_user_id" ON public.action_run USING btree (trigger_user_id);


--
-- Name: IDX_action_run_workflow_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_run_workflow_id" ON public.action_run USING btree (workflow_id);


--
-- Name: IDX_action_runner_last_active; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_runner_last_active" ON public.action_runner USING btree (last_active);


--
-- Name: IDX_action_runner_last_online; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_runner_last_online" ON public.action_runner USING btree (last_online);


--
-- Name: IDX_action_runner_owner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_runner_owner_id" ON public.action_runner USING btree (owner_id);


--
-- Name: IDX_action_runner_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_runner_repo_id" ON public.action_runner USING btree (repo_id);


--
-- Name: IDX_action_runner_token_owner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_runner_token_owner_id" ON public.action_runner_token USING btree (owner_id);


--
-- Name: IDX_action_runner_token_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_runner_token_repo_id" ON public.action_runner_token USING btree (repo_id);


--
-- Name: IDX_action_schedule_owner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_schedule_owner_id" ON public.action_schedule USING btree (owner_id);


--
-- Name: IDX_action_schedule_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_schedule_repo_id" ON public.action_schedule USING btree (repo_id);


--
-- Name: IDX_action_schedule_spec_next; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_schedule_spec_next" ON public.action_schedule_spec USING btree (next);


--
-- Name: IDX_action_schedule_spec_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_schedule_spec_repo_id" ON public.action_schedule_spec USING btree (repo_id);


--
-- Name: IDX_action_schedule_spec_schedule_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_schedule_spec_schedule_id" ON public.action_schedule_spec USING btree (schedule_id);


--
-- Name: IDX_action_task_commit_sha; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_task_commit_sha" ON public.action_task USING btree (commit_sha);


--
-- Name: IDX_action_task_output_task_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_task_output_task_id" ON public.action_task_output USING btree (task_id);


--
-- Name: IDX_action_task_owner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_task_owner_id" ON public.action_task USING btree (owner_id);


--
-- Name: IDX_action_task_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_task_repo_id" ON public.action_task USING btree (repo_id);


--
-- Name: IDX_action_task_runner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_task_runner_id" ON public.action_task USING btree (runner_id);


--
-- Name: IDX_action_task_started; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_task_started" ON public.action_task USING btree (started);


--
-- Name: IDX_action_task_status; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_task_status" ON public.action_task USING btree (status);


--
-- Name: IDX_action_task_step_index; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_task_step_index" ON public.action_task_step USING btree (index);


--
-- Name: IDX_action_task_step_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_task_step_repo_id" ON public.action_task_step USING btree (repo_id);


--
-- Name: IDX_action_task_step_status; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_task_step_status" ON public.action_task_step USING btree (status);


--
-- Name: IDX_action_task_step_task_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_task_step_task_id" ON public.action_task_step USING btree (task_id);


--
-- Name: IDX_action_task_stopped_log_expired; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_task_stopped_log_expired" ON public.action_task USING btree (stopped, log_expired);


--
-- Name: IDX_action_task_token_last_eight; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_task_token_last_eight" ON public.action_task USING btree (token_last_eight);


--
-- Name: IDX_action_task_updated; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_task_updated" ON public.action_task USING btree (updated);


--
-- Name: IDX_action_tasks_version_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_tasks_version_repo_id" ON public.action_tasks_version USING btree (repo_id);


--
-- Name: IDX_action_user_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_user_id" ON public.action USING btree (user_id);


--
-- Name: IDX_action_variable_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_action_variable_repo_id" ON public.action_variable USING btree (repo_id);


--
-- Name: IDX_attachment_comment_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_attachment_comment_id" ON public.attachment USING btree (comment_id);


--
-- Name: IDX_attachment_issue_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_attachment_issue_id" ON public.attachment USING btree (issue_id);


--
-- Name: IDX_attachment_release_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_attachment_release_id" ON public.attachment USING btree (release_id);


--
-- Name: IDX_attachment_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_attachment_repo_id" ON public.attachment USING btree (repo_id);


--
-- Name: IDX_attachment_uploader_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_attachment_uploader_id" ON public.attachment USING btree (uploader_id);


--
-- Name: IDX_auth_token_expires_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_auth_token_expires_unix" ON public.auth_token USING btree (expires_unix);


--
-- Name: IDX_auth_token_user_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_auth_token_user_id" ON public.auth_token USING btree (user_id);


--
-- Name: IDX_branch_deleted_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_branch_deleted_unix" ON public.branch USING btree (deleted_unix);


--
-- Name: IDX_branch_is_deleted; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_branch_is_deleted" ON public.branch USING btree (is_deleted);


--
-- Name: IDX_collaboration_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_collaboration_created_unix" ON public.collaboration USING btree (created_unix);


--
-- Name: IDX_collaboration_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_collaboration_repo_id" ON public.collaboration USING btree (repo_id);


--
-- Name: IDX_collaboration_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_collaboration_updated_unix" ON public.collaboration USING btree (updated_unix);


--
-- Name: IDX_collaboration_user_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_collaboration_user_id" ON public.collaboration USING btree (user_id);


--
-- Name: IDX_comment_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_comment_created_unix" ON public.comment USING btree (created_unix);


--
-- Name: IDX_comment_dependent_issue_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_comment_dependent_issue_id" ON public.comment USING btree (dependent_issue_id);


--
-- Name: IDX_comment_issue_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_comment_issue_id" ON public.comment USING btree (issue_id);


--
-- Name: IDX_comment_poster_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_comment_poster_id" ON public.comment USING btree (poster_id);


--
-- Name: IDX_comment_ref_comment_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_comment_ref_comment_id" ON public.comment USING btree (ref_comment_id);


--
-- Name: IDX_comment_ref_issue_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_comment_ref_issue_id" ON public.comment USING btree (ref_issue_id);


--
-- Name: IDX_comment_ref_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_comment_ref_repo_id" ON public.comment USING btree (ref_repo_id);


--
-- Name: IDX_comment_review_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_comment_review_id" ON public.comment USING btree (review_id);


--
-- Name: IDX_comment_type; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_comment_type" ON public.comment USING btree (type);


--
-- Name: IDX_comment_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_comment_updated_unix" ON public.comment USING btree (updated_unix);


--
-- Name: IDX_commit_status_context_hash; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_commit_status_context_hash" ON public.commit_status USING btree (context_hash);


--
-- Name: IDX_commit_status_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_commit_status_created_unix" ON public.commit_status USING btree (created_unix);


--
-- Name: IDX_commit_status_index; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_commit_status_index" ON public.commit_status USING btree (index);


--
-- Name: IDX_commit_status_index_max_index; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_commit_status_index_max_index" ON public.commit_status_index USING btree (max_index);


--
-- Name: IDX_commit_status_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_commit_status_repo_id" ON public.commit_status USING btree (repo_id);


--
-- Name: IDX_commit_status_sha; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_commit_status_sha" ON public.commit_status USING btree (sha);


--
-- Name: IDX_commit_status_summary_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_commit_status_summary_repo_id" ON public.commit_status_summary USING btree (repo_id);


--
-- Name: IDX_commit_status_summary_sha; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_commit_status_summary_sha" ON public.commit_status_summary USING btree (sha);


--
-- Name: IDX_commit_status_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_commit_status_updated_unix" ON public.commit_status USING btree (updated_unix);


--
-- Name: IDX_dbfs_data_meta_offset; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_dbfs_data_meta_offset" ON public.dbfs_data USING btree (meta_id, blob_offset);


--
-- Name: IDX_deploy_key_key_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_deploy_key_key_id" ON public.deploy_key USING btree (key_id);


--
-- Name: IDX_deploy_key_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_deploy_key_repo_id" ON public.deploy_key USING btree (repo_id);


--
-- Name: IDX_email_address_uid; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_email_address_uid" ON public.email_address USING btree (uid);


--
-- Name: IDX_external_login_user_provider; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_external_login_user_provider" ON public.external_login_user USING btree (provider);


--
-- Name: IDX_external_login_user_user_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_external_login_user_user_id" ON public.external_login_user USING btree (user_id);


--
-- Name: IDX_follow_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_follow_created_unix" ON public.follow USING btree (created_unix);


--
-- Name: IDX_gpg_key_key_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_gpg_key_key_id" ON public.gpg_key USING btree (key_id);


--
-- Name: IDX_gpg_key_owner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_gpg_key_owner_id" ON public.gpg_key USING btree (owner_id);


--
-- Name: IDX_hook_task_hook_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_hook_task_hook_id" ON public.hook_task USING btree (hook_id);


--
-- Name: IDX_issue_assignees_assignee_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_assignees_assignee_id" ON public.issue_assignees USING btree (assignee_id);


--
-- Name: IDX_issue_assignees_issue_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_assignees_issue_id" ON public.issue_assignees USING btree (issue_id);


--
-- Name: IDX_issue_closed_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_closed_unix" ON public.issue USING btree (closed_unix);


--
-- Name: IDX_issue_content_history_comment_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_content_history_comment_id" ON public.issue_content_history USING btree (comment_id);


--
-- Name: IDX_issue_content_history_edited_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_content_history_edited_unix" ON public.issue_content_history USING btree (edited_unix);


--
-- Name: IDX_issue_content_history_issue_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_content_history_issue_id" ON public.issue_content_history USING btree (issue_id);


--
-- Name: IDX_issue_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_created_unix" ON public.issue USING btree (created_unix);


--
-- Name: IDX_issue_deadline_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_deadline_unix" ON public.issue USING btree (deadline_unix);


--
-- Name: IDX_issue_index_max_index; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_index_max_index" ON public.issue_index USING btree (max_index);


--
-- Name: IDX_issue_is_closed; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_is_closed" ON public.issue USING btree (is_closed);


--
-- Name: IDX_issue_is_pull; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_is_pull" ON public.issue USING btree (is_pull);


--
-- Name: IDX_issue_milestone_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_milestone_id" ON public.issue USING btree (milestone_id);


--
-- Name: IDX_issue_original_author_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_original_author_id" ON public.issue USING btree (original_author_id);


--
-- Name: IDX_issue_poster_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_poster_id" ON public.issue USING btree (poster_id);


--
-- Name: IDX_issue_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_repo_id" ON public.issue USING btree (repo_id);


--
-- Name: IDX_issue_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_updated_unix" ON public.issue USING btree (updated_unix);


--
-- Name: IDX_issue_user_issue_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_user_issue_id" ON public.issue_user USING btree (issue_id);


--
-- Name: IDX_issue_user_uid; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_issue_user_uid" ON public.issue_user USING btree (uid);


--
-- Name: IDX_label_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_label_created_unix" ON public.label USING btree (created_unix);


--
-- Name: IDX_label_org_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_label_org_id" ON public.label USING btree (org_id);


--
-- Name: IDX_label_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_label_repo_id" ON public.label USING btree (repo_id);


--
-- Name: IDX_label_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_label_updated_unix" ON public.label USING btree (updated_unix);


--
-- Name: IDX_language_stat_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_language_stat_created_unix" ON public.language_stat USING btree (created_unix);


--
-- Name: IDX_language_stat_language; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_language_stat_language" ON public.language_stat USING btree (language);


--
-- Name: IDX_language_stat_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_language_stat_repo_id" ON public.language_stat USING btree (repo_id);


--
-- Name: IDX_lfs_lock_owner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_lfs_lock_owner_id" ON public.lfs_lock USING btree (owner_id);


--
-- Name: IDX_lfs_lock_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_lfs_lock_repo_id" ON public.lfs_lock USING btree (repo_id);


--
-- Name: IDX_lfs_meta_object_oid; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_lfs_meta_object_oid" ON public.lfs_meta_object USING btree (oid);


--
-- Name: IDX_lfs_meta_object_repository_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_lfs_meta_object_repository_id" ON public.lfs_meta_object USING btree (repository_id);


--
-- Name: IDX_lfs_meta_object_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_lfs_meta_object_updated_unix" ON public.lfs_meta_object USING btree (updated_unix);


--
-- Name: IDX_login_source_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_login_source_created_unix" ON public.login_source USING btree (created_unix);


--
-- Name: IDX_login_source_is_active; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_login_source_is_active" ON public.login_source USING btree (is_active);


--
-- Name: IDX_login_source_is_sync_enabled; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_login_source_is_sync_enabled" ON public.login_source USING btree (is_sync_enabled);


--
-- Name: IDX_login_source_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_login_source_updated_unix" ON public.login_source USING btree (updated_unix);


--
-- Name: IDX_milestone_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_milestone_created_unix" ON public.milestone USING btree (created_unix);


--
-- Name: IDX_milestone_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_milestone_repo_id" ON public.milestone USING btree (repo_id);


--
-- Name: IDX_milestone_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_milestone_updated_unix" ON public.milestone USING btree (updated_unix);


--
-- Name: IDX_mirror_next_update_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_mirror_next_update_unix" ON public.mirror USING btree (next_update_unix);


--
-- Name: IDX_mirror_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_mirror_repo_id" ON public.mirror USING btree (repo_id);


--
-- Name: IDX_mirror_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_mirror_updated_unix" ON public.mirror USING btree (updated_unix);


--
-- Name: IDX_notice_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_notice_created_unix" ON public.notice USING btree (created_unix);


--
-- Name: IDX_notification_idx_notification_commit_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_notification_idx_notification_commit_id" ON public.notification USING btree (commit_id);


--
-- Name: IDX_notification_idx_notification_issue_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_notification_idx_notification_issue_id" ON public.notification USING btree (issue_id);


--
-- Name: IDX_notification_idx_notification_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_notification_idx_notification_repo_id" ON public.notification USING btree (repo_id);


--
-- Name: IDX_notification_idx_notification_source; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_notification_idx_notification_source" ON public.notification USING btree (source);


--
-- Name: IDX_notification_idx_notification_status; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_notification_idx_notification_status" ON public.notification USING btree (status);


--
-- Name: IDX_notification_idx_notification_updated_by; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_notification_idx_notification_updated_by" ON public.notification USING btree (updated_by);


--
-- Name: IDX_notification_idx_notification_user_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_notification_idx_notification_user_id" ON public.notification USING btree (user_id);


--
-- Name: IDX_notification_u_s_uu; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_notification_u_s_uu" ON public.notification USING btree (user_id, status, updated_unix);


--
-- Name: IDX_oauth2_application_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_oauth2_application_created_unix" ON public.oauth2_application USING btree (created_unix);


--
-- Name: IDX_oauth2_application_uid; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_oauth2_application_uid" ON public.oauth2_application USING btree (uid);


--
-- Name: IDX_oauth2_application_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_oauth2_application_updated_unix" ON public.oauth2_application USING btree (updated_unix);


--
-- Name: IDX_oauth2_authorization_code_valid_until; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_oauth2_authorization_code_valid_until" ON public.oauth2_authorization_code USING btree (valid_until);


--
-- Name: IDX_oauth2_grant_application_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_oauth2_grant_application_id" ON public.oauth2_grant USING btree (application_id);


--
-- Name: IDX_oauth2_grant_user_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_oauth2_grant_user_id" ON public.oauth2_grant USING btree (user_id);


--
-- Name: IDX_org_user_is_public; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_org_user_is_public" ON public.org_user USING btree (is_public);


--
-- Name: IDX_org_user_org_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_org_user_org_id" ON public.org_user USING btree (org_id);


--
-- Name: IDX_org_user_uid; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_org_user_uid" ON public.org_user USING btree (uid);


--
-- Name: IDX_package_blob_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_blob_created_unix" ON public.package_blob USING btree (created_unix);


--
-- Name: IDX_package_blob_hash_md5; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_blob_hash_md5" ON public.package_blob USING btree (hash_md5);


--
-- Name: IDX_package_blob_hash_sha1; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_blob_hash_sha1" ON public.package_blob USING btree (hash_sha1);


--
-- Name: IDX_package_blob_hash_sha256; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_blob_hash_sha256" ON public.package_blob USING btree (hash_sha256);


--
-- Name: IDX_package_blob_hash_sha512; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_blob_hash_sha512" ON public.package_blob USING btree (hash_sha512);


--
-- Name: IDX_package_blob_upload_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_blob_upload_updated_unix" ON public.package_blob_upload USING btree (updated_unix);


--
-- Name: IDX_package_cleanup_rule_enabled; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_cleanup_rule_enabled" ON public.package_cleanup_rule USING btree (enabled);


--
-- Name: IDX_package_cleanup_rule_owner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_cleanup_rule_owner_id" ON public.package_cleanup_rule USING btree (owner_id);


--
-- Name: IDX_package_cleanup_rule_type; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_cleanup_rule_type" ON public.package_cleanup_rule USING btree (type);


--
-- Name: IDX_package_file_blob_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_file_blob_id" ON public.package_file USING btree (blob_id);


--
-- Name: IDX_package_file_composite_key; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_file_composite_key" ON public.package_file USING btree (composite_key);


--
-- Name: IDX_package_file_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_file_created_unix" ON public.package_file USING btree (created_unix);


--
-- Name: IDX_package_file_lower_name; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_file_lower_name" ON public.package_file USING btree (lower_name);


--
-- Name: IDX_package_file_version_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_file_version_id" ON public.package_file USING btree (version_id);


--
-- Name: IDX_package_lower_name; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_lower_name" ON public.package USING btree (lower_name);


--
-- Name: IDX_package_owner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_owner_id" ON public.package USING btree (owner_id);


--
-- Name: IDX_package_property_name; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_property_name" ON public.package_property USING btree (name);


--
-- Name: IDX_package_property_ref_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_property_ref_id" ON public.package_property USING btree (ref_id);


--
-- Name: IDX_package_property_ref_type; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_property_ref_type" ON public.package_property USING btree (ref_type);


--
-- Name: IDX_package_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_repo_id" ON public.package USING btree (repo_id);


--
-- Name: IDX_package_type; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_type" ON public.package USING btree (type);


--
-- Name: IDX_package_version_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_version_created_unix" ON public.package_version USING btree (created_unix);


--
-- Name: IDX_package_version_is_internal; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_version_is_internal" ON public.package_version USING btree (is_internal);


--
-- Name: IDX_package_version_lower_version; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_version_lower_version" ON public.package_version USING btree (lower_version);


--
-- Name: IDX_package_version_package_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_package_version_package_id" ON public.package_version USING btree (package_id);


--
-- Name: IDX_project_board_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_project_board_created_unix" ON public.project_board USING btree (created_unix);


--
-- Name: IDX_project_board_project_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_project_board_project_id" ON public.project_board USING btree (project_id);


--
-- Name: IDX_project_board_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_project_board_updated_unix" ON public.project_board USING btree (updated_unix);


--
-- Name: IDX_project_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_project_created_unix" ON public.project USING btree (created_unix);


--
-- Name: IDX_project_is_closed; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_project_is_closed" ON public.project USING btree (is_closed);


--
-- Name: IDX_project_issue_issue_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_project_issue_issue_id" ON public.project_issue USING btree (issue_id);


--
-- Name: IDX_project_issue_project_board_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_project_issue_project_board_id" ON public.project_issue USING btree (project_board_id);


--
-- Name: IDX_project_issue_project_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_project_issue_project_id" ON public.project_issue USING btree (project_id);


--
-- Name: IDX_project_owner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_project_owner_id" ON public.project USING btree (owner_id);


--
-- Name: IDX_project_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_project_repo_id" ON public.project USING btree (repo_id);


--
-- Name: IDX_project_title; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_project_title" ON public.project USING btree (title);


--
-- Name: IDX_project_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_project_updated_unix" ON public.project USING btree (updated_unix);


--
-- Name: IDX_public_key_fingerprint; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_public_key_fingerprint" ON public.public_key USING btree (fingerprint);


--
-- Name: IDX_public_key_owner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_public_key_owner_id" ON public.public_key USING btree (owner_id);


--
-- Name: IDX_pull_auto_merge_doer_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_pull_auto_merge_doer_id" ON public.pull_auto_merge USING btree (doer_id);


--
-- Name: IDX_pull_request_base_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_pull_request_base_repo_id" ON public.pull_request USING btree (base_repo_id);


--
-- Name: IDX_pull_request_has_merged; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_pull_request_has_merged" ON public.pull_request USING btree (has_merged);


--
-- Name: IDX_pull_request_head_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_pull_request_head_repo_id" ON public.pull_request USING btree (head_repo_id);


--
-- Name: IDX_pull_request_issue_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_pull_request_issue_id" ON public.pull_request USING btree (issue_id);


--
-- Name: IDX_pull_request_merged_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_pull_request_merged_unix" ON public.pull_request USING btree (merged_unix);


--
-- Name: IDX_pull_request_merger_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_pull_request_merger_id" ON public.pull_request USING btree (merger_id);


--
-- Name: IDX_push_mirror_last_update; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_push_mirror_last_update" ON public.push_mirror USING btree (last_update);


--
-- Name: IDX_push_mirror_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_push_mirror_repo_id" ON public.push_mirror USING btree (repo_id);


--
-- Name: IDX_reaction_comment_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_reaction_comment_id" ON public.reaction USING btree (comment_id);


--
-- Name: IDX_reaction_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_reaction_created_unix" ON public.reaction USING btree (created_unix);


--
-- Name: IDX_reaction_issue_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_reaction_issue_id" ON public.reaction USING btree (issue_id);


--
-- Name: IDX_reaction_original_author; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_reaction_original_author" ON public.reaction USING btree (original_author);


--
-- Name: IDX_reaction_original_author_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_reaction_original_author_id" ON public.reaction USING btree (original_author_id);


--
-- Name: IDX_reaction_type; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_reaction_type" ON public.reaction USING btree (type);


--
-- Name: IDX_reaction_user_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_reaction_user_id" ON public.reaction USING btree (user_id);


--
-- Name: IDX_release_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_release_created_unix" ON public.release USING btree (created_unix);


--
-- Name: IDX_release_original_author_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_release_original_author_id" ON public.release USING btree (original_author_id);


--
-- Name: IDX_release_publisher_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_release_publisher_id" ON public.release USING btree (publisher_id);


--
-- Name: IDX_release_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_release_repo_id" ON public.release USING btree (repo_id);


--
-- Name: IDX_release_sha1; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_release_sha1" ON public.release USING btree (sha1);


--
-- Name: IDX_release_tag_name; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_release_tag_name" ON public.release USING btree (tag_name);


--
-- Name: IDX_renamed_branch_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_renamed_branch_repo_id" ON public.renamed_branch USING btree (repo_id);


--
-- Name: IDX_repo_archiver_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repo_archiver_created_unix" ON public.repo_archiver USING btree (created_unix);


--
-- Name: IDX_repo_archiver_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repo_archiver_repo_id" ON public.repo_archiver USING btree (repo_id);


--
-- Name: IDX_repo_indexer_status_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repo_indexer_status_s" ON public.repo_indexer_status USING btree (repo_id, indexer_type);


--
-- Name: IDX_repo_license_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repo_license_created_unix" ON public.repo_license USING btree (created_unix);


--
-- Name: IDX_repo_license_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repo_license_updated_unix" ON public.repo_license USING btree (updated_unix);


--
-- Name: IDX_repo_redirect_lower_name; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repo_redirect_lower_name" ON public.repo_redirect USING btree (lower_name);


--
-- Name: IDX_repo_transfer_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repo_transfer_created_unix" ON public.repo_transfer USING btree (created_unix);


--
-- Name: IDX_repo_transfer_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repo_transfer_updated_unix" ON public.repo_transfer USING btree (updated_unix);


--
-- Name: IDX_repo_unit_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repo_unit_created_unix" ON public.repo_unit USING btree (created_unix);


--
-- Name: IDX_repo_unit_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repo_unit_s" ON public.repo_unit USING btree (repo_id, type);


--
-- Name: IDX_repository_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repository_created_unix" ON public.repository USING btree (created_unix);


--
-- Name: IDX_repository_fork_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repository_fork_id" ON public.repository USING btree (fork_id);


--
-- Name: IDX_repository_is_archived; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repository_is_archived" ON public.repository USING btree (is_archived);


--
-- Name: IDX_repository_is_empty; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repository_is_empty" ON public.repository USING btree (is_empty);


--
-- Name: IDX_repository_is_fork; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repository_is_fork" ON public.repository USING btree (is_fork);


--
-- Name: IDX_repository_is_mirror; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repository_is_mirror" ON public.repository USING btree (is_mirror);


--
-- Name: IDX_repository_is_private; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repository_is_private" ON public.repository USING btree (is_private);


--
-- Name: IDX_repository_is_template; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repository_is_template" ON public.repository USING btree (is_template);


--
-- Name: IDX_repository_lower_name; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repository_lower_name" ON public.repository USING btree (lower_name);


--
-- Name: IDX_repository_name; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repository_name" ON public.repository USING btree (name);


--
-- Name: IDX_repository_original_service_type; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repository_original_service_type" ON public.repository USING btree (original_service_type);


--
-- Name: IDX_repository_owner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repository_owner_id" ON public.repository USING btree (owner_id);


--
-- Name: IDX_repository_template_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repository_template_id" ON public.repository USING btree (template_id);


--
-- Name: IDX_repository_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_repository_updated_unix" ON public.repository USING btree (updated_unix);


--
-- Name: IDX_review_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_review_created_unix" ON public.review USING btree (created_unix);


--
-- Name: IDX_review_issue_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_review_issue_id" ON public.review USING btree (issue_id);


--
-- Name: IDX_review_reviewer_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_review_reviewer_id" ON public.review USING btree (reviewer_id);


--
-- Name: IDX_review_state_pull_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_review_state_pull_id" ON public.review_state USING btree (pull_id);


--
-- Name: IDX_review_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_review_updated_unix" ON public.review USING btree (updated_unix);


--
-- Name: IDX_secret_owner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_secret_owner_id" ON public.secret USING btree (owner_id);


--
-- Name: IDX_secret_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_secret_repo_id" ON public.secret USING btree (repo_id);


--
-- Name: IDX_star_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_star_created_unix" ON public.star USING btree (created_unix);


--
-- Name: IDX_stopwatch_issue_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_stopwatch_issue_id" ON public.stopwatch USING btree (issue_id);


--
-- Name: IDX_stopwatch_user_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_stopwatch_user_id" ON public.stopwatch USING btree (user_id);


--
-- Name: IDX_task_doer_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_task_doer_id" ON public.task USING btree (doer_id);


--
-- Name: IDX_task_owner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_task_owner_id" ON public.task USING btree (owner_id);


--
-- Name: IDX_task_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_task_repo_id" ON public.task USING btree (repo_id);


--
-- Name: IDX_task_status; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_task_status" ON public.task USING btree (status);


--
-- Name: IDX_team_invite_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_team_invite_created_unix" ON public.team_invite USING btree (created_unix);


--
-- Name: IDX_team_invite_org_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_team_invite_org_id" ON public.team_invite USING btree (org_id);


--
-- Name: IDX_team_invite_team_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_team_invite_team_id" ON public.team_invite USING btree (team_id);


--
-- Name: IDX_team_invite_token; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_team_invite_token" ON public.team_invite USING btree (token);


--
-- Name: IDX_team_invite_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_team_invite_updated_unix" ON public.team_invite USING btree (updated_unix);


--
-- Name: IDX_team_org_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_team_org_id" ON public.team USING btree (org_id);


--
-- Name: IDX_team_repo_org_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_team_repo_org_id" ON public.team_repo USING btree (org_id);


--
-- Name: IDX_team_unit_org_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_team_unit_org_id" ON public.team_unit USING btree (org_id);


--
-- Name: IDX_team_user_org_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_team_user_org_id" ON public.team_user USING btree (org_id);


--
-- Name: IDX_topic_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_topic_created_unix" ON public.topic USING btree (created_unix);


--
-- Name: IDX_topic_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_topic_updated_unix" ON public.topic USING btree (updated_unix);


--
-- Name: IDX_tracked_time_issue_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_tracked_time_issue_id" ON public.tracked_time USING btree (issue_id);


--
-- Name: IDX_tracked_time_user_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_tracked_time_user_id" ON public.tracked_time USING btree (user_id);


--
-- Name: IDX_two_factor_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_two_factor_created_unix" ON public.two_factor USING btree (created_unix);


--
-- Name: IDX_two_factor_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_two_factor_updated_unix" ON public.two_factor USING btree (updated_unix);


--
-- Name: IDX_user_badge_user_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_user_badge_user_id" ON public.user_badge USING btree (user_id);


--
-- Name: IDX_user_blocking_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_user_blocking_created_unix" ON public.user_blocking USING btree (created_unix);


--
-- Name: IDX_user_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_user_created_unix" ON public."user" USING btree (created_unix);


--
-- Name: IDX_user_is_active; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_user_is_active" ON public."user" USING btree (is_active);


--
-- Name: IDX_user_last_login_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_user_last_login_unix" ON public."user" USING btree (last_login_unix);


--
-- Name: IDX_user_open_id_uid; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_user_open_id_uid" ON public.user_open_id USING btree (uid);


--
-- Name: IDX_user_redirect_lower_name; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_user_redirect_lower_name" ON public.user_redirect USING btree (lower_name);


--
-- Name: IDX_user_setting_setting_key; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_user_setting_setting_key" ON public.user_setting USING btree (setting_key);


--
-- Name: IDX_user_setting_user_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_user_setting_user_id" ON public.user_setting USING btree (user_id);


--
-- Name: IDX_user_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_user_updated_unix" ON public."user" USING btree (updated_unix);


--
-- Name: IDX_watch_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_watch_created_unix" ON public.watch USING btree (created_unix);


--
-- Name: IDX_watch_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_watch_updated_unix" ON public.watch USING btree (updated_unix);


--
-- Name: IDX_webauthn_credential_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_webauthn_credential_created_unix" ON public.webauthn_credential USING btree (created_unix);


--
-- Name: IDX_webauthn_credential_credential_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_webauthn_credential_credential_id" ON public.webauthn_credential USING btree (credential_id);


--
-- Name: IDX_webauthn_credential_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_webauthn_credential_updated_unix" ON public.webauthn_credential USING btree (updated_unix);


--
-- Name: IDX_webauthn_credential_user_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_webauthn_credential_user_id" ON public.webauthn_credential USING btree (user_id);


--
-- Name: IDX_webhook_created_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_webhook_created_unix" ON public.webhook USING btree (created_unix);


--
-- Name: IDX_webhook_is_active; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_webhook_is_active" ON public.webhook USING btree (is_active);


--
-- Name: IDX_webhook_owner_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_webhook_owner_id" ON public.webhook USING btree (owner_id);


--
-- Name: IDX_webhook_repo_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_webhook_repo_id" ON public.webhook USING btree (repo_id);


--
-- Name: IDX_webhook_updated_unix; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE INDEX "IDX_webhook_updated_unix" ON public.webhook USING btree (updated_unix);


--
-- Name: UQE_access_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_access_s" ON public.access USING btree (user_id, repo_id);


--
-- Name: UQE_access_token_token_hash; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_access_token_token_hash" ON public.access_token USING btree (token_hash);


--
-- Name: UQE_action_artifact_runid_name_path; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_action_artifact_runid_name_path" ON public.action_artifact USING btree (run_id, artifact_path, artifact_name);


--
-- Name: UQE_action_run_repo_index; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_action_run_repo_index" ON public.action_run USING btree (repo_id, index);


--
-- Name: UQE_action_runner_token_hash; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_action_runner_token_hash" ON public.action_runner USING btree (token_hash);


--
-- Name: UQE_action_runner_token_token; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_action_runner_token_token" ON public.action_runner_token USING btree (token);


--
-- Name: UQE_action_runner_uuid; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_action_runner_uuid" ON public.action_runner USING btree (uuid);


--
-- Name: UQE_action_task_output_task_id_output_key; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_action_task_output_task_id_output_key" ON public.action_task_output USING btree (task_id, output_key);


--
-- Name: UQE_action_task_step_task_index; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_action_task_step_task_index" ON public.action_task_step USING btree (task_id, index);


--
-- Name: UQE_action_task_token_hash; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_action_task_token_hash" ON public.action_task USING btree (token_hash);


--
-- Name: UQE_action_tasks_version_owner_repo; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_action_tasks_version_owner_repo" ON public.action_tasks_version USING btree (owner_id, repo_id);


--
-- Name: UQE_action_variable_owner_repo_name; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_action_variable_owner_repo_name" ON public.action_variable USING btree (owner_id, repo_id, name);


--
-- Name: UQE_attachment_uuid; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_attachment_uuid" ON public.attachment USING btree (uuid);


--
-- Name: UQE_badge_slug; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_badge_slug" ON public.badge USING btree (slug);


--
-- Name: UQE_branch_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_branch_s" ON public.branch USING btree (repo_id, name);


--
-- Name: UQE_collaboration_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_collaboration_s" ON public.collaboration USING btree (repo_id, user_id);


--
-- Name: UQE_commit_status_index_repo_sha; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_commit_status_index_repo_sha" ON public.commit_status_index USING btree (repo_id, sha);


--
-- Name: UQE_commit_status_repo_sha_index; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_commit_status_repo_sha_index" ON public.commit_status USING btree (index, repo_id, sha);


--
-- Name: UQE_commit_status_summary_repo_id_sha; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_commit_status_summary_repo_id_sha" ON public.commit_status_summary USING btree (repo_id, sha);


--
-- Name: UQE_dbfs_meta_full_path; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_dbfs_meta_full_path" ON public.dbfs_meta USING btree (full_path);


--
-- Name: UQE_deploy_key_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_deploy_key_s" ON public.deploy_key USING btree (key_id, repo_id);


--
-- Name: UQE_email_address_email; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_email_address_email" ON public.email_address USING btree (email);


--
-- Name: UQE_email_address_lower_email; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_email_address_lower_email" ON public.email_address USING btree (lower_email);


--
-- Name: UQE_email_hash_email; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_email_hash_email" ON public.email_hash USING btree (email);


--
-- Name: UQE_follow_follow; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_follow_follow" ON public.follow USING btree (user_id, follow_id);


--
-- Name: UQE_hook_task_uuid; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_hook_task_uuid" ON public.hook_task USING btree (uuid);


--
-- Name: UQE_issue_dependency_issue_dependency; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_issue_dependency_issue_dependency" ON public.issue_dependency USING btree (issue_id, dependency_id);


--
-- Name: UQE_issue_label_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_issue_label_s" ON public.issue_label USING btree (issue_id, label_id);


--
-- Name: UQE_issue_pin_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_issue_pin_s" ON public.issue_pin USING btree (repo_id, issue_id);


--
-- Name: UQE_issue_repo_index; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_issue_repo_index" ON public.issue USING btree (repo_id, index);


--
-- Name: UQE_issue_user_uid_to_issue; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_issue_user_uid_to_issue" ON public.issue_user USING btree (uid, issue_id);


--
-- Name: UQE_issue_watch_watch; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_issue_watch_watch" ON public.issue_watch USING btree (user_id, issue_id);


--
-- Name: UQE_language_stat_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_language_stat_s" ON public.language_stat USING btree (repo_id, language);


--
-- Name: UQE_lfs_meta_object_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_lfs_meta_object_s" ON public.lfs_meta_object USING btree (oid, repository_id);


--
-- Name: UQE_login_source_name; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_login_source_name" ON public.login_source USING btree (name);


--
-- Name: UQE_oauth2_application_client_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_oauth2_application_client_id" ON public.oauth2_application USING btree (client_id);


--
-- Name: UQE_oauth2_authorization_code_code; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_oauth2_authorization_code_code" ON public.oauth2_authorization_code USING btree (code);


--
-- Name: UQE_oauth2_grant_user_application; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_oauth2_grant_user_application" ON public.oauth2_grant USING btree (user_id, application_id);


--
-- Name: UQE_org_user_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_org_user_s" ON public.org_user USING btree (uid, org_id);


--
-- Name: UQE_package_blob_md5; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_package_blob_md5" ON public.package_blob USING btree (hash_md5);


--
-- Name: UQE_package_blob_sha1; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_package_blob_sha1" ON public.package_blob USING btree (hash_sha1);


--
-- Name: UQE_package_blob_sha256; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_package_blob_sha256" ON public.package_blob USING btree (hash_sha256);


--
-- Name: UQE_package_blob_sha512; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_package_blob_sha512" ON public.package_blob USING btree (hash_sha512);


--
-- Name: UQE_package_cleanup_rule_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_package_cleanup_rule_s" ON public.package_cleanup_rule USING btree (owner_id, type);


--
-- Name: UQE_package_file_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_package_file_s" ON public.package_file USING btree (version_id, lower_name, composite_key);


--
-- Name: UQE_package_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_package_s" ON public.package USING btree (owner_id, type, lower_name);


--
-- Name: UQE_package_version_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_package_version_s" ON public.package_version USING btree (package_id, lower_version);


--
-- Name: UQE_protected_branch_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_protected_branch_s" ON public.protected_branch USING btree (repo_id, branch_name);


--
-- Name: UQE_pull_auto_merge_pull_id; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_pull_auto_merge_pull_id" ON public.pull_auto_merge USING btree (pull_id);


--
-- Name: UQE_reaction_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_reaction_s" ON public.reaction USING btree (type, issue_id, comment_id, user_id, original_author_id, original_author);


--
-- Name: UQE_release_n; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_release_n" ON public.release USING btree (repo_id, tag_name);


--
-- Name: UQE_repo_archiver_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_repo_archiver_s" ON public.repo_archiver USING btree (repo_id, type, commit_id);


--
-- Name: UQE_repo_license_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_repo_license_s" ON public.repo_license USING btree (repo_id, license);


--
-- Name: UQE_repo_redirect_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_repo_redirect_s" ON public.repo_redirect USING btree (owner_id, lower_name);


--
-- Name: UQE_repository_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_repository_s" ON public.repository USING btree (owner_id, lower_name);


--
-- Name: UQE_review_state_pull_commit_user; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_review_state_pull_commit_user" ON public.review_state USING btree (user_id, pull_id, commit_sha);


--
-- Name: UQE_secret_owner_repo_name; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_secret_owner_repo_name" ON public.secret USING btree (owner_id, repo_id, name);


--
-- Name: UQE_star_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_star_s" ON public.star USING btree (uid, repo_id);


--
-- Name: UQE_system_setting_setting_key; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_system_setting_setting_key" ON public.system_setting USING btree (setting_key);


--
-- Name: UQE_team_invite_team_mail; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_team_invite_team_mail" ON public.team_invite USING btree (team_id, email);


--
-- Name: UQE_team_repo_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_team_repo_s" ON public.team_repo USING btree (team_id, repo_id);


--
-- Name: UQE_team_unit_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_team_unit_s" ON public.team_unit USING btree (team_id, type);


--
-- Name: UQE_team_user_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_team_user_s" ON public.team_user USING btree (team_id, uid);


--
-- Name: UQE_topic_name; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_topic_name" ON public.topic USING btree (name);


--
-- Name: UQE_two_factor_uid; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_two_factor_uid" ON public.two_factor USING btree (uid);


--
-- Name: UQE_upload_uuid; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_upload_uuid" ON public.upload USING btree (uuid);


--
-- Name: UQE_user_blocking_block; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_user_blocking_block" ON public.user_blocking USING btree (blocker_id, blockee_id);


--
-- Name: UQE_user_lower_name; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_user_lower_name" ON public."user" USING btree (lower_name);


--
-- Name: UQE_user_name; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_user_name" ON public."user" USING btree (name);


--
-- Name: UQE_user_open_id_uri; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_user_open_id_uri" ON public.user_open_id USING btree (uri);


--
-- Name: UQE_user_redirect_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_user_redirect_s" ON public.user_redirect USING btree (lower_name);


--
-- Name: UQE_user_setting_key_userid; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_user_setting_key_userid" ON public.user_setting USING btree (user_id, setting_key);


--
-- Name: UQE_watch_watch; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_watch_watch" ON public.watch USING btree (user_id, repo_id);


--
-- Name: UQE_webauthn_credential_s; Type: INDEX; Schema: public; Owner: gitea_user
--

CREATE UNIQUE INDEX "UQE_webauthn_credential_s" ON public.webauthn_credential USING btree (lower_name, user_id);


--
-- PostgreSQL database dump complete
--

\unrestrict SMMJbywCVsqbysM8AsgU3HpnrxbSx6SoZOp4yuSA7vDXj5qSCXww5nI8e6ciyaC

