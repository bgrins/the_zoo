--
-- PostgreSQL database dump
--

\restrict zoo

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

--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: entry_sorting_direction; Type: TYPE; Schema: public; Owner: miniflux_user
--

CREATE TYPE public.entry_sorting_direction AS ENUM (
    'asc',
    'desc'
);


ALTER TYPE public.entry_sorting_direction OWNER TO miniflux_user;

--
-- Name: entry_sorting_order; Type: TYPE; Schema: public; Owner: miniflux_user
--

CREATE TYPE public.entry_sorting_order AS ENUM (
    'published_at',
    'created_at'
);


ALTER TYPE public.entry_sorting_order OWNER TO miniflux_user;

--
-- Name: entry_status; Type: TYPE; Schema: public; Owner: miniflux_user
--

CREATE TYPE public.entry_status AS ENUM (
    'unread',
    'read',
    'removed'
);


ALTER TYPE public.entry_status OWNER TO miniflux_user;

--
-- Name: webapp_display_mode; Type: TYPE; Schema: public; Owner: miniflux_user
--

CREATE TYPE public.webapp_display_mode AS ENUM (
    'fullscreen',
    'standalone',
    'minimal-ui',
    'browser'
);


ALTER TYPE public.webapp_display_mode OWNER TO miniflux_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: acme_cache; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.acme_cache (
    key character varying(400) NOT NULL,
    data bytea NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.acme_cache OWNER TO miniflux_user;

--
-- Name: api_keys; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.api_keys (
    id integer NOT NULL,
    user_id integer NOT NULL,
    token text NOT NULL,
    description text NOT NULL,
    last_used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.api_keys OWNER TO miniflux_user;

--
-- Name: api_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: miniflux_user
--

CREATE SEQUENCE public.api_keys_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.api_keys_id_seq OWNER TO miniflux_user;

--
-- Name: api_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: miniflux_user
--

ALTER SEQUENCE public.api_keys_id_seq OWNED BY public.api_keys.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.categories (
    id integer NOT NULL,
    user_id integer NOT NULL,
    title text NOT NULL,
    hide_globally boolean DEFAULT false NOT NULL
);


ALTER TABLE public.categories OWNER TO miniflux_user;

--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: miniflux_user
--

CREATE SEQUENCE public.categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categories_id_seq OWNER TO miniflux_user;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: miniflux_user
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: enclosures; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.enclosures (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    entry_id bigint NOT NULL,
    url text NOT NULL,
    size bigint DEFAULT 0,
    mime_type text DEFAULT ''::text,
    media_progression integer DEFAULT 0
);


ALTER TABLE public.enclosures OWNER TO miniflux_user;

--
-- Name: enclosures_id_seq; Type: SEQUENCE; Schema: public; Owner: miniflux_user
--

CREATE SEQUENCE public.enclosures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.enclosures_id_seq OWNER TO miniflux_user;

--
-- Name: enclosures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: miniflux_user
--

ALTER SEQUENCE public.enclosures_id_seq OWNED BY public.enclosures.id;


--
-- Name: entries; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.entries (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    feed_id bigint NOT NULL,
    hash text NOT NULL,
    published_at timestamp with time zone NOT NULL,
    title text NOT NULL,
    url text NOT NULL,
    author text,
    content text,
    status public.entry_status DEFAULT 'unread'::public.entry_status,
    starred boolean DEFAULT false,
    comments_url text DEFAULT ''::text,
    document_vectors tsvector,
    changed_at timestamp with time zone NOT NULL,
    share_code text DEFAULT ''::text NOT NULL,
    reading_time integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tags text[] DEFAULT '{}'::text[]
);


ALTER TABLE public.entries OWNER TO miniflux_user;

--
-- Name: entries_id_seq; Type: SEQUENCE; Schema: public; Owner: miniflux_user
--

CREATE SEQUENCE public.entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.entries_id_seq OWNER TO miniflux_user;

--
-- Name: entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: miniflux_user
--

ALTER SEQUENCE public.entries_id_seq OWNED BY public.entries.id;


--
-- Name: feed_icons; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.feed_icons (
    feed_id bigint NOT NULL,
    icon_id bigint NOT NULL
);


ALTER TABLE public.feed_icons OWNER TO miniflux_user;

--
-- Name: feeds; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.feeds (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    category_id integer NOT NULL,
    title text NOT NULL,
    feed_url text NOT NULL,
    site_url text NOT NULL,
    checked_at timestamp with time zone DEFAULT now(),
    etag_header text DEFAULT ''::text,
    last_modified_header text DEFAULT ''::text,
    parsing_error_msg text DEFAULT ''::text,
    parsing_error_count integer DEFAULT 0,
    scraper_rules text DEFAULT ''::text,
    rewrite_rules text DEFAULT ''::text,
    crawler boolean DEFAULT false,
    username text DEFAULT ''::text,
    password text DEFAULT ''::text,
    user_agent text DEFAULT ''::text,
    disabled boolean DEFAULT false,
    next_check_at timestamp with time zone DEFAULT now(),
    ignore_http_cache boolean DEFAULT false,
    fetch_via_proxy boolean DEFAULT false,
    blocklist_rules text DEFAULT ''::text NOT NULL,
    keeplist_rules text DEFAULT ''::text NOT NULL,
    allow_self_signed_certificates boolean DEFAULT false NOT NULL,
    cookie text DEFAULT ''::text,
    hide_globally boolean DEFAULT false NOT NULL,
    url_rewrite_rules text DEFAULT ''::text NOT NULL,
    no_media_player boolean DEFAULT false,
    apprise_service_urls text DEFAULT ''::text,
    disable_http2 boolean DEFAULT false,
    description text DEFAULT ''::text,
    ntfy_enabled boolean DEFAULT false,
    ntfy_priority integer DEFAULT 3,
    webhook_url text DEFAULT ''::text,
    pushover_enabled boolean DEFAULT false,
    pushover_priority integer DEFAULT 0,
    ntfy_topic text DEFAULT ''::text,
    proxy_url text DEFAULT ''::text
);


ALTER TABLE public.feeds OWNER TO miniflux_user;

--
-- Name: feeds_id_seq; Type: SEQUENCE; Schema: public; Owner: miniflux_user
--

CREATE SEQUENCE public.feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.feeds_id_seq OWNER TO miniflux_user;

--
-- Name: feeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: miniflux_user
--

ALTER SEQUENCE public.feeds_id_seq OWNED BY public.feeds.id;


--
-- Name: icons; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.icons (
    id bigint NOT NULL,
    hash text NOT NULL,
    mime_type text NOT NULL,
    content bytea NOT NULL,
    external_id text DEFAULT ''::text
);


ALTER TABLE public.icons OWNER TO miniflux_user;

--
-- Name: icons_id_seq; Type: SEQUENCE; Schema: public; Owner: miniflux_user
--

CREATE SEQUENCE public.icons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.icons_id_seq OWNER TO miniflux_user;

--
-- Name: icons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: miniflux_user
--

ALTER SEQUENCE public.icons_id_seq OWNED BY public.icons.id;


--
-- Name: integrations; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.integrations (
    user_id integer NOT NULL,
    pinboard_enabled boolean DEFAULT false,
    pinboard_token text DEFAULT ''::text,
    pinboard_tags text DEFAULT 'miniflux'::text,
    pinboard_mark_as_unread boolean DEFAULT false,
    instapaper_enabled boolean DEFAULT false,
    instapaper_username text DEFAULT ''::text,
    instapaper_password text DEFAULT ''::text,
    fever_enabled boolean DEFAULT false,
    fever_username text DEFAULT ''::text,
    fever_token text DEFAULT ''::text,
    wallabag_enabled boolean DEFAULT false,
    wallabag_url text DEFAULT ''::text,
    wallabag_client_id text DEFAULT ''::text,
    wallabag_client_secret text DEFAULT ''::text,
    wallabag_username text DEFAULT ''::text,
    wallabag_password text DEFAULT ''::text,
    nunux_keeper_enabled boolean DEFAULT false,
    nunux_keeper_url text DEFAULT ''::text,
    nunux_keeper_api_key text DEFAULT ''::text,
    pocket_enabled boolean DEFAULT false,
    pocket_access_token text DEFAULT ''::text,
    pocket_consumer_key text DEFAULT ''::text,
    telegram_bot_enabled boolean DEFAULT false,
    telegram_bot_token text DEFAULT ''::text,
    telegram_bot_chat_id text DEFAULT ''::text,
    googlereader_enabled boolean DEFAULT false,
    googlereader_username text DEFAULT ''::text,
    googlereader_password text DEFAULT ''::text,
    espial_enabled boolean DEFAULT false,
    espial_url text DEFAULT ''::text,
    espial_api_key text DEFAULT ''::text,
    espial_tags text DEFAULT 'miniflux'::text,
    linkding_enabled boolean DEFAULT false,
    linkding_url text DEFAULT ''::text,
    linkding_api_key text DEFAULT ''::text,
    wallabag_only_url boolean DEFAULT false,
    matrix_bot_enabled boolean DEFAULT false,
    matrix_bot_user text DEFAULT ''::text,
    matrix_bot_password text DEFAULT ''::text,
    matrix_bot_url text DEFAULT ''::text,
    matrix_bot_chat_id text DEFAULT ''::text,
    linkding_tags text DEFAULT ''::text,
    linkding_mark_as_unread boolean DEFAULT false,
    notion_enabled boolean DEFAULT false,
    notion_token text DEFAULT ''::text,
    notion_page_id text DEFAULT ''::text,
    readwise_enabled boolean DEFAULT false,
    readwise_api_key text DEFAULT ''::text,
    apprise_enabled boolean DEFAULT false,
    apprise_url text DEFAULT ''::text,
    apprise_services_url text DEFAULT ''::text,
    shiori_enabled boolean DEFAULT false,
    shiori_url text DEFAULT ''::text,
    shiori_username text DEFAULT ''::text,
    shiori_password text DEFAULT ''::text,
    shaarli_enabled boolean DEFAULT false,
    shaarli_url text DEFAULT ''::text,
    shaarli_api_secret text DEFAULT ''::text,
    webhook_enabled boolean DEFAULT false,
    webhook_url text DEFAULT ''::text,
    webhook_secret text DEFAULT ''::text,
    telegram_bot_topic_id integer,
    telegram_bot_disable_web_page_preview boolean DEFAULT false,
    telegram_bot_disable_notification boolean DEFAULT false,
    telegram_bot_disable_buttons boolean DEFAULT false,
    rssbridge_enabled boolean DEFAULT false,
    rssbridge_url text DEFAULT ''::text,
    omnivore_enabled boolean DEFAULT false,
    omnivore_api_key text DEFAULT ''::text,
    omnivore_url text DEFAULT ''::text,
    linkace_enabled boolean DEFAULT false,
    linkace_url text DEFAULT ''::text,
    linkace_api_key text DEFAULT ''::text,
    linkace_tags text DEFAULT ''::text,
    linkace_is_private boolean DEFAULT true,
    linkace_check_disabled boolean DEFAULT true,
    linkwarden_enabled boolean DEFAULT false,
    linkwarden_url text DEFAULT ''::text,
    linkwarden_api_key text DEFAULT ''::text,
    readeck_enabled boolean DEFAULT false,
    readeck_only_url boolean DEFAULT false,
    readeck_url text DEFAULT ''::text,
    readeck_api_key text DEFAULT ''::text,
    readeck_labels text DEFAULT ''::text,
    raindrop_enabled boolean DEFAULT false,
    raindrop_token text DEFAULT ''::text,
    raindrop_collection_id text DEFAULT ''::text,
    raindrop_tags text DEFAULT ''::text,
    betula_url text DEFAULT ''::text,
    betula_token text DEFAULT ''::text,
    betula_enabled boolean DEFAULT false,
    ntfy_enabled boolean DEFAULT false,
    ntfy_url text DEFAULT ''::text,
    ntfy_topic text DEFAULT ''::text,
    ntfy_api_token text DEFAULT ''::text,
    ntfy_username text DEFAULT ''::text,
    ntfy_password text DEFAULT ''::text,
    ntfy_icon_url text DEFAULT ''::text,
    cubox_enabled boolean DEFAULT false,
    cubox_api_link text DEFAULT ''::text,
    discord_enabled boolean DEFAULT false,
    discord_webhook_link text DEFAULT ''::text,
    ntfy_internal_links boolean DEFAULT false,
    slack_enabled boolean DEFAULT false,
    slack_webhook_link text DEFAULT ''::text,
    pushover_enabled boolean DEFAULT false,
    pushover_user text DEFAULT ''::text,
    pushover_token text DEFAULT ''::text,
    pushover_device text DEFAULT ''::text,
    pushover_prefix text DEFAULT ''::text,
    rssbridge_token text DEFAULT ''::text
);


ALTER TABLE public.integrations OWNER TO miniflux_user;

--
-- Name: schema_version; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.schema_version (
    version text NOT NULL
);


ALTER TABLE public.schema_version OWNER TO miniflux_user;

--
-- Name: sessions; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.sessions (
    id text NOT NULL,
    data jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.sessions OWNER TO miniflux_user;

--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.user_sessions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    token text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    user_agent text,
    ip inet
);


ALTER TABLE public.user_sessions OWNER TO miniflux_user;

--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: miniflux_user
--

CREATE SEQUENCE public.sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sessions_id_seq OWNER TO miniflux_user;

--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: miniflux_user
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.user_sessions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username text NOT NULL,
    password text,
    is_admin boolean DEFAULT false,
    language text DEFAULT 'en_US'::text,
    timezone text DEFAULT 'UTC'::text,
    theme text DEFAULT 'light_serif'::text,
    last_login_at timestamp with time zone,
    entry_direction public.entry_sorting_direction DEFAULT 'asc'::public.entry_sorting_direction,
    keyboard_shortcuts boolean DEFAULT true,
    entries_per_page integer DEFAULT 100,
    show_reading_time boolean DEFAULT true,
    entry_swipe boolean DEFAULT true,
    stylesheet text DEFAULT ''::text NOT NULL,
    google_id text DEFAULT ''::text NOT NULL,
    openid_connect_id text DEFAULT ''::text NOT NULL,
    display_mode public.webapp_display_mode DEFAULT 'standalone'::public.webapp_display_mode,
    entry_order public.entry_sorting_order DEFAULT 'published_at'::public.entry_sorting_order,
    default_reading_speed integer DEFAULT 265,
    cjk_reading_speed integer DEFAULT 500,
    default_home_page text DEFAULT 'unread'::text,
    categories_sorting_order text DEFAULT 'unread_count'::text NOT NULL,
    gesture_nav text DEFAULT 'tap'::text,
    mark_read_on_view boolean DEFAULT true,
    media_playback_rate numeric DEFAULT 1,
    block_filter_entry_rules text DEFAULT ''::text NOT NULL,
    keep_filter_entry_rules text DEFAULT ''::text NOT NULL,
    mark_read_on_media_player_completion boolean DEFAULT false,
    custom_js text DEFAULT ''::text NOT NULL,
    external_font_hosts text DEFAULT ''::text NOT NULL,
    always_open_external_links boolean DEFAULT false
);


ALTER TABLE public.users OWNER TO miniflux_user;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: miniflux_user
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO miniflux_user;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: miniflux_user
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: webauthn_credentials; Type: TABLE; Schema: public; Owner: miniflux_user
--

CREATE TABLE public.webauthn_credentials (
    handle bytea NOT NULL,
    cred_id bytea NOT NULL,
    user_id integer NOT NULL,
    public_key bytea NOT NULL,
    attestation_type character varying(255) NOT NULL,
    aaguid bytea,
    sign_count bigint,
    clone_warning boolean,
    name text,
    added_on timestamp with time zone DEFAULT now(),
    last_seen_on timestamp with time zone DEFAULT now()
);


ALTER TABLE public.webauthn_credentials OWNER TO miniflux_user;

--
-- Name: api_keys id; Type: DEFAULT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.api_keys ALTER COLUMN id SET DEFAULT nextval('public.api_keys_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: enclosures id; Type: DEFAULT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.enclosures ALTER COLUMN id SET DEFAULT nextval('public.enclosures_id_seq'::regclass);


--
-- Name: entries id; Type: DEFAULT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.entries ALTER COLUMN id SET DEFAULT nextval('public.entries_id_seq'::regclass);


--
-- Name: feeds id; Type: DEFAULT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.feeds ALTER COLUMN id SET DEFAULT nextval('public.feeds_id_seq'::regclass);


--
-- Name: icons id; Type: DEFAULT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.icons ALTER COLUMN id SET DEFAULT nextval('public.icons_id_seq'::regclass);


--
-- Name: user_sessions id; Type: DEFAULT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.user_sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: acme_cache; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.acme_cache (key, data, updated_at) FROM stdin;
\.


--
-- Data for Name: api_keys; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.api_keys (id, user_id, token, description, last_used_at, created_at) FROM stdin;
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.categories (id, user_id, title, hide_globally) FROM stdin;
1	1	All	f
2	2	All	f
3	3	All	f
4	4	All	f
5	5	All	f
6	6	All	f
7	7	All	f
8	8	All	f
9	9	All	f
10	10	All	f
11	11	All	f
12	12	All	f
13	13	All	f
14	14	All	f
\.


--
-- Data for Name: enclosures; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.enclosures (id, user_id, entry_id, url, size, mime_type, media_progression) FROM stdin;
\.


--
-- Data for Name: entries; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.entries (id, user_id, feed_id, hash, published_at, title, url, author, content, status, starred, comments_url, document_vectors, changed_at, share_code, reading_time, created_at, tags) FROM stdin;
\.


--
-- Data for Name: feed_icons; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.feed_icons (feed_id, icon_id) FROM stdin;
\.


--
-- Data for Name: feeds; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.feeds (id, user_id, category_id, title, feed_url, site_url, checked_at, etag_header, last_modified_header, parsing_error_msg, parsing_error_count, scraper_rules, rewrite_rules, crawler, username, password, user_agent, disabled, next_check_at, ignore_http_cache, fetch_via_proxy, blocklist_rules, keeplist_rules, allow_self_signed_certificates, cookie, hide_globally, url_rewrite_rules, no_media_player, apprise_service_urls, disable_http2, description, ntfy_enabled, ntfy_priority, webhook_url, pushover_enabled, pushover_priority, ntfy_topic, proxy_url) FROM stdin;
\.


--
-- Data for Name: icons; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.icons (id, hash, mime_type, content, external_id) FROM stdin;
\.


--
-- Data for Name: integrations; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.integrations (user_id, pinboard_enabled, pinboard_token, pinboard_tags, pinboard_mark_as_unread, instapaper_enabled, instapaper_username, instapaper_password, fever_enabled, fever_username, fever_token, wallabag_enabled, wallabag_url, wallabag_client_id, wallabag_client_secret, wallabag_username, wallabag_password, nunux_keeper_enabled, nunux_keeper_url, nunux_keeper_api_key, pocket_enabled, pocket_access_token, pocket_consumer_key, telegram_bot_enabled, telegram_bot_token, telegram_bot_chat_id, googlereader_enabled, googlereader_username, googlereader_password, espial_enabled, espial_url, espial_api_key, espial_tags, linkding_enabled, linkding_url, linkding_api_key, wallabag_only_url, matrix_bot_enabled, matrix_bot_user, matrix_bot_password, matrix_bot_url, matrix_bot_chat_id, linkding_tags, linkding_mark_as_unread, notion_enabled, notion_token, notion_page_id, readwise_enabled, readwise_api_key, apprise_enabled, apprise_url, apprise_services_url, shiori_enabled, shiori_url, shiori_username, shiori_password, shaarli_enabled, shaarli_url, shaarli_api_secret, webhook_enabled, webhook_url, webhook_secret, telegram_bot_topic_id, telegram_bot_disable_web_page_preview, telegram_bot_disable_notification, telegram_bot_disable_buttons, rssbridge_enabled, rssbridge_url, omnivore_enabled, omnivore_api_key, omnivore_url, linkace_enabled, linkace_url, linkace_api_key, linkace_tags, linkace_is_private, linkace_check_disabled, linkwarden_enabled, linkwarden_url, linkwarden_api_key, readeck_enabled, readeck_only_url, readeck_url, readeck_api_key, readeck_labels, raindrop_enabled, raindrop_token, raindrop_collection_id, raindrop_tags, betula_url, betula_token, betula_enabled, ntfy_enabled, ntfy_url, ntfy_topic, ntfy_api_token, ntfy_username, ntfy_password, ntfy_icon_url, cubox_enabled, cubox_api_link, discord_enabled, discord_webhook_link, ntfy_internal_links, slack_enabled, slack_webhook_link, pushover_enabled, pushover_user, pushover_token, pushover_device, pushover_prefix, rssbridge_token) FROM stdin;
1	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
2	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
3	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
4	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
5	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
6	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
7	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
8	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
9	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
10	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
11	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
12	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
13	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
14	f		miniflux	f	f			f			f						f			f			f			f			f			miniflux	f			f	f						f	f			f		f			f				f			f			\N	f	f	f	f		f			f				t	t	f			f	f				f						f	f							f		f		f	f		f					
\.


--
-- Data for Name: schema_version; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.schema_version (version) FROM stdin;
110
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.users (id, username, password, is_admin, language, timezone, theme, last_login_at, entry_direction, keyboard_shortcuts, entries_per_page, show_reading_time, entry_swipe, stylesheet, google_id, openid_connect_id, display_mode, entry_order, default_reading_speed, cjk_reading_speed, default_home_page, categories_sorting_order, gesture_nav, mark_read_on_view, media_playback_rate, block_filter_entry_rules, keep_filter_entry_rules, mark_read_on_media_player_completion, custom_js, external_font_hosts, always_open_external_links) FROM stdin;
1	admin	$2a$10$0SKn0M.0CITOeRYkgPaY3ePGgxb338/fc3VMlAopvfhyn71woRuMq	t	en_US	UTC	light_serif	2026-09-19 18:55:36.020742+00	asc	t	100	t	t			bf76d497-ef2e-51e2-a14d-3860791929c9	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
2	alice	$2a$10$yDniENeGz1foJ3BZXv42femw/CGbSyuLSQIsYbrYOHtHWmpM0srku	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			b608913a-c0d2-5141-808a-30eb1809bae2	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
3	bob	$2a$10$pgpvYwri9f9GSp8O1JtU8ue8q9fqoiIByoyNOuDdEEqJ16h0jL58y	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			21d2ca5f-25db-581a-9c58-7ed3b3aaef3e	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
4	charlie	$2a$10$RMokmwTDnc/FTxb.7B7lMuaI1Pm6H7Q6s6yP7cZUeKqMeKEU8zGvq	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			0fae1fa0-0dfd-511c-a865-69be6961afe7	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
5	diana	$2a$10$.ddJxK/DmNdpXYqbf3JVwuqSbBdMd2GJfsDF53abZYwXARwNjfvne	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			d6092304-e8bd-5344-8abd-28f18db5f9eb	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
6	eve	$2a$10$I4jZetIJ8UjToKVc53PDXOMJcCMykIJZug3o99T.3JpkC7tETMdOi	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			a906f37f-b3c5-5bd2-972e-5497fd6e7926	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
7	frank	$2a$10$UYFGqIeLWVKGWVsAhaNPleO7SO43FB3uHwjvBA5eJWwDrj/wRVTcy	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			007d86cc-b436-514b-ae85-57af1da0b729	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
8	grace	$2a$10$4NOKf059gIWS8i0XcKMnMuveU6/Ob9ri5ovxn7lUjfMytlCEwbgqq	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			b569288b-49f7-51a5-86d8-baa37149f20a	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
9	demo	$2a$10$pwzzSUC8/3UFfmiXObw7ne6jPhdbW7r2c43Qz0iCK4KaycYrr3cSS	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			b88e24e7-5ad4-55ca-9a67-face778e43a3	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
10	user1	$2a$10$UoRWN5fir3VeVoGSiq8Dku92NSggekx297buL2GDbQaqIvf9yFUkW	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			5200e09c-0a5d-50ea-b36f-6ff1367a5e52	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
11	alex.chen	$2a$10$zMHYpk0wvTUoR.aCvwMxReP0UgBp15TdWpAjf64huyCCapFv0C/Ya	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			4ef29f33-7958-5ff5-af29-73ff36834988	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
12	blake.sullivan	$2a$10$3RW3n7SSpgDJEFUQs9/w2OyDAVZeHzuVXFPGbn1KD1uSXzlWntQI.	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			94a79ee0-00af-5aea-ba5e-384191bc89c2	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
13	mallory	$2a$10$WKa4b99ehJJVVPuU95OzsuXBFpCRZEOwvss6idmqqb4/0u9i1fFUG	f	en_US	UTC	light_serif	\N	asc	t	100	t	t			82ba4bb8-8b3c-5b06-a481-351f81a2a7ea	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
14	analytics_user	$2a$10$dMK109i9BOSqQFF/M.CusOAt2mh7l5pK7mTsXHpWrdmYtwN2VmYr6	t	en_US	UTC	light_serif	\N	asc	t	100	t	t			3df993b7-ed35-5349-a475-67d23d52a52a	standalone	published_at	265	500	unread	unread_count	tap	t	1			f			f
\.


--
-- Data for Name: webauthn_credentials; Type: TABLE DATA; Schema: public; Owner: miniflux_user
--

COPY public.webauthn_credentials (handle, cred_id, user_id, public_key, attestation_type, aaguid, sign_count, clone_warning, name, added_on, last_seen_on) FROM stdin;
\.


--
-- Name: api_keys_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.api_keys_id_seq', 1, false);


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.categories_id_seq', 14, true);


--
-- Name: enclosures_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.enclosures_id_seq', 1, false);


--
-- Name: entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.entries_id_seq', 1, false);


--
-- Name: feeds_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.feeds_id_seq', 1, false);


--
-- Name: icons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.icons_id_seq', 1, false);


--
-- Name: sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.sessions_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: miniflux_user
--

SELECT pg_catalog.setval('public.users_id_seq', 14, true);


--
-- Name: acme_cache acme_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.acme_cache
    ADD CONSTRAINT acme_cache_pkey PRIMARY KEY (key);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: api_keys api_keys_token_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_token_key UNIQUE (token);


--
-- Name: api_keys api_keys_user_id_description_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_user_id_description_key UNIQUE (user_id, description);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: categories categories_user_id_title_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_user_id_title_key UNIQUE (user_id, title);


--
-- Name: enclosures enclosures_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.enclosures
    ADD CONSTRAINT enclosures_pkey PRIMARY KEY (id);


--
-- Name: entries entries_feed_id_hash_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.entries
    ADD CONSTRAINT entries_feed_id_hash_key UNIQUE (feed_id, hash);


--
-- Name: entries entries_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.entries
    ADD CONSTRAINT entries_pkey PRIMARY KEY (id);


--
-- Name: feed_icons feed_icons_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.feed_icons
    ADD CONSTRAINT feed_icons_pkey PRIMARY KEY (feed_id, icon_id);


--
-- Name: feeds feeds_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.feeds
    ADD CONSTRAINT feeds_pkey PRIMARY KEY (id);


--
-- Name: feeds feeds_user_id_feed_url_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.feeds
    ADD CONSTRAINT feeds_user_id_feed_url_key UNIQUE (user_id, feed_url);


--
-- Name: icons icons_hash_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.icons
    ADD CONSTRAINT icons_hash_key UNIQUE (hash);


--
-- Name: icons icons_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.icons
    ADD CONSTRAINT icons_pkey PRIMARY KEY (id);


--
-- Name: integrations integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.integrations
    ADD CONSTRAINT integrations_pkey PRIMARY KEY (user_id);


--
-- Name: user_sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey1; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey1 PRIMARY KEY (id);


--
-- Name: user_sessions sessions_token_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT sessions_token_key UNIQUE (token);


--
-- Name: user_sessions sessions_user_id_token_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT sessions_user_id_token_key UNIQUE (user_id, token);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: webauthn_credentials webauthn_credentials_cred_id_key; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_cred_id_key UNIQUE (cred_id);


--
-- Name: webauthn_credentials webauthn_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_pkey PRIMARY KEY (handle);


--
-- Name: document_vectors_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX document_vectors_idx ON public.entries USING gin (document_vectors);


--
-- Name: enclosures_entry_id_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX enclosures_entry_id_idx ON public.enclosures USING btree (entry_id);


--
-- Name: enclosures_user_entry_url_unique_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE UNIQUE INDEX enclosures_user_entry_url_unique_idx ON public.enclosures USING btree (user_id, entry_id, md5(url));


--
-- Name: entries_feed_id_status_hash_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_feed_id_status_hash_idx ON public.entries USING btree (feed_id, status, hash);


--
-- Name: entries_feed_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_feed_idx ON public.entries USING btree (feed_id);


--
-- Name: entries_id_user_status_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_id_user_status_idx ON public.entries USING btree (id, user_id, status);


--
-- Name: entries_share_code_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE UNIQUE INDEX entries_share_code_idx ON public.entries USING btree (share_code) WHERE (share_code <> ''::text);


--
-- Name: entries_user_feed_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_user_feed_idx ON public.entries USING btree (user_id, feed_id);


--
-- Name: entries_user_id_status_starred_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_user_id_status_starred_idx ON public.entries USING btree (user_id, status, starred);


--
-- Name: entries_user_status_changed_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_user_status_changed_idx ON public.entries USING btree (user_id, status, changed_at);


--
-- Name: entries_user_status_changed_published_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_user_status_changed_published_idx ON public.entries USING btree (user_id, status, changed_at, published_at);


--
-- Name: entries_user_status_created_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_user_status_created_idx ON public.entries USING btree (user_id, status, created_at);


--
-- Name: entries_user_status_feed_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_user_status_feed_idx ON public.entries USING btree (user_id, status, feed_id);


--
-- Name: entries_user_status_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_user_status_idx ON public.entries USING btree (user_id, status);


--
-- Name: entries_user_status_published_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX entries_user_status_published_idx ON public.entries USING btree (user_id, status, published_at);


--
-- Name: feeds_feed_id_hide_globally_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX feeds_feed_id_hide_globally_idx ON public.feeds USING btree (id, hide_globally);


--
-- Name: feeds_user_category_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE INDEX feeds_user_category_idx ON public.feeds USING btree (user_id, category_id);


--
-- Name: icons_external_id_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE UNIQUE INDEX icons_external_id_idx ON public.icons USING btree (external_id) WHERE (external_id <> ''::text);


--
-- Name: users_google_id_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE UNIQUE INDEX users_google_id_idx ON public.users USING btree (google_id) WHERE (google_id <> ''::text);


--
-- Name: users_openid_connect_id_idx; Type: INDEX; Schema: public; Owner: miniflux_user
--

CREATE UNIQUE INDEX users_openid_connect_id_idx ON public.users USING btree (openid_connect_id) WHERE (openid_connect_id <> ''::text);


--
-- Name: api_keys api_keys_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: categories categories_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: enclosures enclosures_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.enclosures
    ADD CONSTRAINT enclosures_entry_id_fkey FOREIGN KEY (entry_id) REFERENCES public.entries(id) ON DELETE CASCADE;


--
-- Name: enclosures enclosures_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.enclosures
    ADD CONSTRAINT enclosures_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: entries entries_feed_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.entries
    ADD CONSTRAINT entries_feed_id_fkey FOREIGN KEY (feed_id) REFERENCES public.feeds(id) ON DELETE CASCADE;


--
-- Name: entries entries_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.entries
    ADD CONSTRAINT entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: feed_icons feed_icons_feed_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.feed_icons
    ADD CONSTRAINT feed_icons_feed_id_fkey FOREIGN KEY (feed_id) REFERENCES public.feeds(id) ON DELETE CASCADE;


--
-- Name: feed_icons feed_icons_icon_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.feed_icons
    ADD CONSTRAINT feed_icons_icon_id_fkey FOREIGN KEY (icon_id) REFERENCES public.icons(id) ON DELETE CASCADE;


--
-- Name: feeds feeds_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.feeds
    ADD CONSTRAINT feeds_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- Name: feeds feeds_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.feeds
    ADD CONSTRAINT feeds_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: webauthn_credentials webauthn_credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: miniflux_user
--

ALTER TABLE ONLY public.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict zoo

