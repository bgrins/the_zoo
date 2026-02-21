--
-- PostgreSQL database dump
--

\restrict h4IlctqZaQddMJnyEOvhp8K7mdVld0BfVfmihj9hDQ9aSyMgBZ26SC8forwl60U

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
-- Name: channel_bookmark_type; Type: TYPE; Schema: public; Owner: mattermost_user
--

CREATE TYPE public.channel_bookmark_type AS ENUM (
    'link',
    'file'
);


ALTER TYPE public.channel_bookmark_type OWNER TO mattermost_user;

--
-- Name: channel_type; Type: TYPE; Schema: public; Owner: mattermost_user
--

CREATE TYPE public.channel_type AS ENUM (
    'P',
    'G',
    'O',
    'D'
);


ALTER TYPE public.channel_type OWNER TO mattermost_user;

--
-- Name: outgoingoauthconnections_granttype; Type: TYPE; Schema: public; Owner: mattermost_user
--

CREATE TYPE public.outgoingoauthconnections_granttype AS ENUM (
    'client_credentials',
    'password'
);


ALTER TYPE public.outgoingoauthconnections_granttype OWNER TO mattermost_user;

--
-- Name: property_field_type; Type: TYPE; Schema: public; Owner: mattermost_user
--

CREATE TYPE public.property_field_type AS ENUM (
    'text',
    'select',
    'multiselect',
    'date',
    'user',
    'multiuser'
);


ALTER TYPE public.property_field_type OWNER TO mattermost_user;

--
-- Name: team_type; Type: TYPE; Schema: public; Owner: mattermost_user
--

CREATE TYPE public.team_type AS ENUM (
    'I',
    'O'
);


ALTER TYPE public.team_type OWNER TO mattermost_user;

--
-- Name: upload_session_type; Type: TYPE; Schema: public; Owner: mattermost_user
--

CREATE TYPE public.upload_session_type AS ENUM (
    'attachment',
    'import'
);


ALTER TYPE public.upload_session_type OWNER TO mattermost_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audits; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.audits (
    id character varying(26) NOT NULL,
    createat bigint,
    userid character varying(26),
    action character varying(512),
    extrainfo character varying(1024),
    ipaddress character varying(64),
    sessionid character varying(26)
);


ALTER TABLE public.audits OWNER TO mattermost_user;

--
-- Name: bots; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.bots (
    userid character varying(26) NOT NULL,
    description character varying(1024),
    ownerid character varying(190),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    lasticonupdate bigint
);


ALTER TABLE public.bots OWNER TO mattermost_user;

--
-- Name: calls; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.calls (
    id character varying(26) NOT NULL,
    channelid character varying(26),
    startat bigint,
    endat bigint,
    createat bigint,
    deleteat bigint,
    title character varying(256),
    postid character varying(26),
    threadid character varying(26),
    ownerid character varying(26),
    participants jsonb NOT NULL,
    stats jsonb NOT NULL,
    props jsonb NOT NULL
);


ALTER TABLE public.calls OWNER TO mattermost_user;

--
-- Name: calls_channels; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.calls_channels (
    channelid character varying(26) NOT NULL,
    enabled boolean,
    props jsonb NOT NULL
);


ALTER TABLE public.calls_channels OWNER TO mattermost_user;

--
-- Name: calls_jobs; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.calls_jobs (
    id character varying(26) NOT NULL,
    callid character varying(26),
    type character varying(64),
    creatorid character varying(26),
    initat bigint,
    startat bigint,
    endat bigint,
    props jsonb NOT NULL
);


ALTER TABLE public.calls_jobs OWNER TO mattermost_user;

--
-- Name: calls_sessions; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.calls_sessions (
    id character varying(26) NOT NULL,
    callid character varying(26),
    userid character varying(26),
    joinat bigint,
    unmuted boolean,
    raisedhand bigint
);


ALTER TABLE public.calls_sessions OWNER TO mattermost_user;

--
-- Name: channelbookmarks; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.channelbookmarks (
    id character varying(26) NOT NULL,
    ownerid character varying(26) NOT NULL,
    channelid character varying(26) NOT NULL,
    fileinfoid character varying(26) DEFAULT NULL::character varying,
    createat bigint DEFAULT 0,
    updateat bigint DEFAULT 0,
    deleteat bigint DEFAULT 0,
    displayname text DEFAULT ''::text,
    sortorder integer DEFAULT 0,
    linkurl text,
    imageurl text,
    emoji character varying(64) DEFAULT NULL::character varying,
    type public.channel_bookmark_type DEFAULT 'link'::public.channel_bookmark_type,
    originalid character varying(26) DEFAULT NULL::character varying,
    parentid character varying(26) DEFAULT NULL::character varying
);


ALTER TABLE public.channelbookmarks OWNER TO mattermost_user;

--
-- Name: channelmemberhistory; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.channelmemberhistory (
    channelid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    jointime bigint NOT NULL,
    leavetime bigint
);


ALTER TABLE public.channelmemberhistory OWNER TO mattermost_user;

--
-- Name: channelmembers; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.channelmembers (
    channelid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    roles character varying(256),
    lastviewedat bigint,
    msgcount bigint,
    mentioncount bigint,
    notifyprops jsonb,
    lastupdateat bigint,
    schemeuser boolean,
    schemeadmin boolean,
    schemeguest boolean,
    mentioncountroot bigint,
    msgcountroot bigint,
    urgentmentioncount bigint
);


ALTER TABLE public.channelmembers OWNER TO mattermost_user;

--
-- Name: channels; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.channels (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    teamid character varying(26),
    type public.channel_type,
    displayname character varying(64),
    name character varying(64),
    header character varying(1024),
    purpose character varying(250),
    lastpostat bigint,
    totalmsgcount bigint,
    extraupdateat bigint,
    creatorid character varying(26),
    schemeid character varying(26),
    groupconstrained boolean,
    shared boolean,
    totalmsgcountroot bigint,
    lastrootpostat bigint DEFAULT '0'::bigint
);


ALTER TABLE public.channels OWNER TO mattermost_user;

--
-- Name: clusterdiscovery; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.clusterdiscovery (
    id character varying(26) NOT NULL,
    type character varying(64),
    clustername character varying(64),
    hostname character varying(512),
    gossipport integer,
    port integer,
    createat bigint,
    lastpingat bigint
);


ALTER TABLE public.clusterdiscovery OWNER TO mattermost_user;

--
-- Name: commands; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.commands (
    id character varying(26) NOT NULL,
    token character varying(26),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    creatorid character varying(26),
    teamid character varying(26),
    trigger character varying(128),
    method character varying(1),
    username character varying(64),
    iconurl character varying(1024),
    autocomplete boolean,
    autocompletedesc character varying(1024),
    autocompletehint character varying(1024),
    displayname character varying(64),
    description character varying(128),
    url character varying(1024),
    pluginid character varying(190)
);


ALTER TABLE public.commands OWNER TO mattermost_user;

--
-- Name: commandwebhooks; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.commandwebhooks (
    id character varying(26) NOT NULL,
    createat bigint,
    commandid character varying(26),
    userid character varying(26),
    channelid character varying(26),
    rootid character varying(26),
    usecount integer
);


ALTER TABLE public.commandwebhooks OWNER TO mattermost_user;

--
-- Name: compliances; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.compliances (
    id character varying(26) NOT NULL,
    createat bigint,
    userid character varying(26),
    status character varying(64),
    count integer,
    "desc" character varying(512),
    type character varying(64),
    startat bigint,
    endat bigint,
    keywords character varying(512),
    emails character varying(1024)
);


ALTER TABLE public.compliances OWNER TO mattermost_user;

--
-- Name: configurationfiles; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.configurationfiles (
    name character varying(64) NOT NULL,
    data text NOT NULL,
    createat bigint NOT NULL,
    updateat bigint NOT NULL
);


ALTER TABLE public.configurationfiles OWNER TO mattermost_user;

--
-- Name: configurations; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.configurations (
    id character varying(26) NOT NULL,
    value text NOT NULL,
    createat bigint NOT NULL,
    active boolean,
    sha character(64) DEFAULT ''::bpchar
);


ALTER TABLE public.configurations OWNER TO mattermost_user;

--
-- Name: db_config_migrations; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.db_config_migrations (
    version bigint NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.db_config_migrations OWNER TO mattermost_user;

--
-- Name: db_lock; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.db_lock (
    id character varying(64) NOT NULL,
    expireat bigint
);


ALTER TABLE public.db_lock OWNER TO mattermost_user;

--
-- Name: db_migrations; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.db_migrations (
    version bigint NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.db_migrations OWNER TO mattermost_user;

--
-- Name: db_migrations_calls; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.db_migrations_calls (
    version bigint NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.db_migrations_calls OWNER TO mattermost_user;

--
-- Name: desktoptokens; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.desktoptokens (
    token character varying(64) NOT NULL,
    createat bigint NOT NULL,
    userid character varying(26) NOT NULL
);


ALTER TABLE public.desktoptokens OWNER TO mattermost_user;

--
-- Name: drafts; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.drafts (
    createat bigint,
    updateat bigint,
    deleteat bigint,
    userid character varying(26) NOT NULL,
    channelid character varying(26) NOT NULL,
    rootid character varying(26) DEFAULT ''::character varying NOT NULL,
    message character varying(65535),
    props character varying(8000),
    fileids character varying(300),
    priority text
);


ALTER TABLE public.drafts OWNER TO mattermost_user;

--
-- Name: emoji; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.emoji (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    creatorid character varying(26),
    name character varying(64)
);


ALTER TABLE public.emoji OWNER TO mattermost_user;

--
-- Name: fileinfo; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.fileinfo (
    id character varying(26) NOT NULL,
    creatorid character varying(26),
    postid character varying(26),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    path character varying(512),
    thumbnailpath character varying(512),
    previewpath character varying(512),
    name character varying(256),
    extension character varying(64),
    size bigint,
    mimetype character varying(256),
    width integer,
    height integer,
    haspreviewimage boolean,
    minipreview bytea,
    content text,
    remoteid character varying(26),
    archived boolean DEFAULT false NOT NULL,
    channelid character varying(26)
)
WITH (autovacuum_vacuum_scale_factor='0.1', autovacuum_analyze_scale_factor='0.05');


ALTER TABLE public.fileinfo OWNER TO mattermost_user;

--
-- Name: groupchannels; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.groupchannels (
    groupid character varying(26) NOT NULL,
    autoadd boolean,
    schemeadmin boolean,
    createat bigint,
    deleteat bigint,
    updateat bigint,
    channelid character varying(26) NOT NULL
);


ALTER TABLE public.groupchannels OWNER TO mattermost_user;

--
-- Name: groupmembers; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.groupmembers (
    groupid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    createat bigint,
    deleteat bigint
);


ALTER TABLE public.groupmembers OWNER TO mattermost_user;

--
-- Name: groupteams; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.groupteams (
    groupid character varying(26) NOT NULL,
    autoadd boolean,
    schemeadmin boolean,
    createat bigint,
    deleteat bigint,
    updateat bigint,
    teamid character varying(26) NOT NULL
);


ALTER TABLE public.groupteams OWNER TO mattermost_user;

--
-- Name: incomingwebhooks; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.incomingwebhooks (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    userid character varying(26),
    channelid character varying(26),
    teamid character varying(26),
    displayname character varying(64),
    description character varying(500),
    username character varying(255),
    iconurl character varying(1024),
    channellocked boolean
);


ALTER TABLE public.incomingwebhooks OWNER TO mattermost_user;

--
-- Name: ir_category; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.ir_category (
    id character varying(26) NOT NULL,
    name character varying(512) NOT NULL,
    teamid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    collapsed boolean DEFAULT false,
    createat bigint NOT NULL,
    updateat bigint DEFAULT 0 NOT NULL,
    deleteat bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.ir_category OWNER TO mattermost_user;

--
-- Name: ir_category_item; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.ir_category_item (
    type character varying(1) NOT NULL,
    categoryid character varying(26) NOT NULL,
    itemid character varying(26) NOT NULL
);


ALTER TABLE public.ir_category_item OWNER TO mattermost_user;

--
-- Name: ir_channelaction; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.ir_channelaction (
    id character varying(26) NOT NULL,
    channelid character varying(26),
    enabled boolean DEFAULT false,
    deleteat bigint DEFAULT 0 NOT NULL,
    actiontype character varying(65535) NOT NULL,
    triggertype character varying(65535) NOT NULL,
    payload json NOT NULL
);


ALTER TABLE public.ir_channelaction OWNER TO mattermost_user;

--
-- Name: ir_incident; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.ir_incident (
    id character varying(26) NOT NULL,
    name character varying(1024) NOT NULL,
    description character varying(4096) NOT NULL,
    isactive boolean NOT NULL,
    commanderuserid character varying(26) NOT NULL,
    teamid character varying(26) NOT NULL,
    channelid character varying(26) NOT NULL,
    createat bigint NOT NULL,
    endat bigint DEFAULT 0 NOT NULL,
    deleteat bigint DEFAULT 0 NOT NULL,
    activestage bigint NOT NULL,
    postid character varying(26) DEFAULT ''::text NOT NULL,
    playbookid character varying(26) DEFAULT ''::text NOT NULL,
    checklistsjson json NOT NULL,
    activestagetitle character varying(1024) DEFAULT ''::text,
    reminderpostid character varying(26),
    broadcastchannelid character varying(26) DEFAULT ''::text,
    previousreminder bigint DEFAULT 0 NOT NULL,
    remindermessagetemplate character varying(65535) DEFAULT ''::text,
    currentstatus character varying(1024) DEFAULT 'Active'::text NOT NULL,
    reporteruserid character varying(26) DEFAULT ''::text NOT NULL,
    concatenatedinviteduserids character varying(65535) DEFAULT ''::text,
    defaultcommanderid character varying(26) DEFAULT ''::text,
    announcementchannelid character varying(26) DEFAULT ''::text,
    concatenatedwebhookoncreationurls character varying(65535) DEFAULT ''::text,
    concatenatedinvitedgroupids character varying(65535) DEFAULT ''::text,
    retrospective character varying(65535) DEFAULT ''::text,
    messageonjoin character varying(65535) DEFAULT ''::text,
    retrospectivepublishedat bigint DEFAULT 0 NOT NULL,
    retrospectivereminderintervalseconds bigint DEFAULT 0 NOT NULL,
    retrospectivewascanceled boolean DEFAULT false,
    concatenatedwebhookonstatusupdateurls character varying(65535) DEFAULT ''::text,
    laststatusupdateat bigint DEFAULT 0,
    exportchannelonfinishedenabled boolean DEFAULT false NOT NULL,
    categorizechannelenabled boolean DEFAULT false,
    categoryname character varying(65535) DEFAULT ''::text,
    concatenatedbroadcastchannelids character varying(65535),
    channelidtorootid character varying(65535) DEFAULT ''::text,
    remindertimerdefaultseconds bigint DEFAULT 0 NOT NULL,
    statusupdateenabled boolean DEFAULT true,
    retrospectiveenabled boolean DEFAULT true,
    statusupdatebroadcastchannelsenabled boolean DEFAULT false,
    statusupdatebroadcastwebhooksenabled boolean DEFAULT false,
    summarymodifiedat bigint DEFAULT 0 NOT NULL,
    createchannelmemberonnewparticipant boolean DEFAULT true,
    removechannelmemberonremovedparticipant boolean DEFAULT true,
    runtype character varying(32) DEFAULT 'playbook'::character varying
);


ALTER TABLE public.ir_incident OWNER TO mattermost_user;

--
-- Name: ir_metric; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.ir_metric (
    incidentid character varying(26) NOT NULL,
    metricconfigid character varying(26) NOT NULL,
    value bigint,
    published boolean NOT NULL
);


ALTER TABLE public.ir_metric OWNER TO mattermost_user;

--
-- Name: ir_metricconfig; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.ir_metricconfig (
    id character varying(26) NOT NULL,
    playbookid character varying(26) NOT NULL,
    title character varying(512) NOT NULL,
    description character varying(4096) NOT NULL,
    type character varying(32) NOT NULL,
    target bigint,
    ordering smallint DEFAULT 0 NOT NULL,
    deleteat bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.ir_metricconfig OWNER TO mattermost_user;

--
-- Name: ir_playbook; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.ir_playbook (
    id character varying(26) NOT NULL,
    title character varying(1024) NOT NULL,
    description character varying(4096) NOT NULL,
    teamid character varying(26) NOT NULL,
    createpublicincident boolean NOT NULL,
    createat bigint NOT NULL,
    deleteat bigint DEFAULT 0 NOT NULL,
    checklistsjson json NOT NULL,
    numstages bigint DEFAULT 0 NOT NULL,
    numsteps bigint DEFAULT 0 NOT NULL,
    broadcastchannelid character varying(26) DEFAULT ''::text,
    remindermessagetemplate character varying(65535) DEFAULT ''::text,
    remindertimerdefaultseconds bigint DEFAULT 0 NOT NULL,
    concatenatedinviteduserids character varying(65535) DEFAULT ''::text,
    inviteusersenabled boolean DEFAULT false,
    defaultcommanderid character varying(26) DEFAULT ''::text,
    defaultcommanderenabled boolean DEFAULT false,
    announcementchannelid character varying(26) DEFAULT ''::text,
    announcementchannelenabled boolean DEFAULT false,
    concatenatedwebhookoncreationurls character varying(65535) DEFAULT ''::text,
    webhookoncreationenabled boolean DEFAULT false,
    concatenatedinvitedgroupids character varying(65535) DEFAULT ''::text,
    messageonjoin character varying(65535) DEFAULT ''::text,
    messageonjoinenabled boolean DEFAULT false,
    retrospectivereminderintervalseconds bigint DEFAULT 0 NOT NULL,
    retrospectivetemplate character varying(65535),
    concatenatedwebhookonstatusupdateurls character varying(65535) DEFAULT ''::text,
    webhookonstatusupdateenabled boolean DEFAULT false,
    concatenatedsignalanykeywords character varying(65535) DEFAULT ''::text,
    signalanykeywordsenabled boolean DEFAULT false,
    updateat bigint DEFAULT 0 NOT NULL,
    exportchannelonfinishedenabled boolean DEFAULT false NOT NULL,
    categorizechannelenabled boolean DEFAULT false,
    categoryname character varying(65535) DEFAULT ''::text,
    concatenatedbroadcastchannelids character varying(65535),
    broadcastenabled boolean DEFAULT false,
    runsummarytemplate character varying(65535) DEFAULT ''::text,
    channelnametemplate character varying(65535) DEFAULT ''::text,
    statusupdateenabled boolean DEFAULT true,
    retrospectiveenabled boolean DEFAULT true,
    public boolean DEFAULT false,
    runsummarytemplateenabled boolean DEFAULT true,
    createchannelmemberonnewparticipant boolean DEFAULT true,
    removechannelmemberonremovedparticipant boolean DEFAULT true,
    channelid character varying(26) DEFAULT ''::character varying,
    channelmode character varying(32) DEFAULT 'create_new_channel'::character varying
);


ALTER TABLE public.ir_playbook OWNER TO mattermost_user;

--
-- Name: ir_playbookautofollow; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.ir_playbookautofollow (
    playbookid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL
);


ALTER TABLE public.ir_playbookautofollow OWNER TO mattermost_user;

--
-- Name: ir_playbookmember; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.ir_playbookmember (
    playbookid character varying(26) NOT NULL,
    memberid character varying(26) NOT NULL,
    roles character varying(65535)
);


ALTER TABLE public.ir_playbookmember OWNER TO mattermost_user;

--
-- Name: ir_run_participants; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.ir_run_participants (
    userid character varying(26) NOT NULL,
    incidentid character varying(26) NOT NULL,
    isfollower boolean DEFAULT false NOT NULL,
    isparticipant boolean DEFAULT false
);


ALTER TABLE public.ir_run_participants OWNER TO mattermost_user;

--
-- Name: ir_statusposts; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.ir_statusposts (
    incidentid character varying(26) NOT NULL,
    postid character varying(26) NOT NULL
);


ALTER TABLE public.ir_statusposts OWNER TO mattermost_user;

--
-- Name: ir_system; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.ir_system (
    skey character varying(64) NOT NULL,
    svalue character varying(1024)
);


ALTER TABLE public.ir_system OWNER TO mattermost_user;

--
-- Name: ir_timelineevent; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.ir_timelineevent (
    id character varying(26) NOT NULL,
    incidentid character varying(26) NOT NULL,
    createat bigint NOT NULL,
    deleteat bigint DEFAULT 0 NOT NULL,
    eventat bigint NOT NULL,
    eventtype character varying(32) DEFAULT ''::text NOT NULL,
    summary character varying(256) DEFAULT ''::text NOT NULL,
    details character varying(4096) DEFAULT ''::text NOT NULL,
    postid character varying(26) DEFAULT ''::text NOT NULL,
    subjectuserid character varying(26) DEFAULT ''::text NOT NULL,
    creatoruserid character varying(26) DEFAULT ''::text NOT NULL
);


ALTER TABLE public.ir_timelineevent OWNER TO mattermost_user;

--
-- Name: ir_userinfo; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.ir_userinfo (
    id character varying(26) NOT NULL,
    lastdailytododmat bigint,
    digestnotificationsettingsjson json
);


ALTER TABLE public.ir_userinfo OWNER TO mattermost_user;

--
-- Name: ir_viewedchannel; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.ir_viewedchannel (
    channelid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL
);


ALTER TABLE public.ir_viewedchannel OWNER TO mattermost_user;

--
-- Name: jobs; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.jobs (
    id character varying(26) NOT NULL,
    type character varying(32),
    priority bigint,
    createat bigint,
    startat bigint,
    lastactivityat bigint,
    status character varying(32),
    progress bigint,
    data jsonb
);


ALTER TABLE public.jobs OWNER TO mattermost_user;

--
-- Name: licenses; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.licenses (
    id character varying(26) NOT NULL,
    createat bigint,
    bytes character varying(10000)
);


ALTER TABLE public.licenses OWNER TO mattermost_user;

--
-- Name: linkmetadata; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.linkmetadata (
    hash bigint NOT NULL,
    url character varying(2048),
    "timestamp" bigint,
    type character varying(16),
    data jsonb
);


ALTER TABLE public.linkmetadata OWNER TO mattermost_user;

--
-- Name: llm_postmeta; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.llm_postmeta (
    rootpostid text NOT NULL,
    title text NOT NULL
);


ALTER TABLE public.llm_postmeta OWNER TO mattermost_user;

--
-- Name: notifyadmin; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.notifyadmin (
    userid character varying(26) NOT NULL,
    createat bigint,
    requiredplan character varying(100) NOT NULL,
    requiredfeature character varying(255) NOT NULL,
    trial boolean NOT NULL,
    sentat bigint
);


ALTER TABLE public.notifyadmin OWNER TO mattermost_user;

--
-- Name: oauthaccessdata; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.oauthaccessdata (
    token character varying(26) NOT NULL,
    refreshtoken character varying(26),
    redirecturi character varying(256),
    clientid character varying(26),
    userid character varying(26),
    expiresat bigint,
    scope character varying(128)
);


ALTER TABLE public.oauthaccessdata OWNER TO mattermost_user;

--
-- Name: oauthapps; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.oauthapps (
    id character varying(26) NOT NULL,
    creatorid character varying(26),
    createat bigint,
    updateat bigint,
    clientsecret character varying(128),
    name character varying(64),
    description character varying(512),
    callbackurls character varying(1024),
    homepage character varying(256),
    istrusted boolean,
    iconurl character varying(512),
    mattermostappid character varying(32) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.oauthapps OWNER TO mattermost_user;

--
-- Name: oauthauthdata; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.oauthauthdata (
    clientid character varying(26),
    userid character varying(26),
    code character varying(128) NOT NULL,
    expiresin integer,
    createat bigint,
    redirecturi character varying(256),
    state character varying(1024),
    scope character varying(128)
);


ALTER TABLE public.oauthauthdata OWNER TO mattermost_user;

--
-- Name: outgoingoauthconnections; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.outgoingoauthconnections (
    id character varying(26) NOT NULL,
    name character varying(64),
    creatorid character varying(26),
    createat bigint,
    updateat bigint,
    clientid character varying(255),
    clientsecret character varying(255),
    credentialsusername character varying(255),
    credentialspassword character varying(255),
    oauthtokenurl text,
    granttype public.outgoingoauthconnections_granttype DEFAULT 'client_credentials'::public.outgoingoauthconnections_granttype,
    audiences character varying(1024)
);


ALTER TABLE public.outgoingoauthconnections OWNER TO mattermost_user;

--
-- Name: outgoingwebhooks; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.outgoingwebhooks (
    id character varying(26) NOT NULL,
    token character varying(26),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    creatorid character varying(26),
    channelid character varying(26),
    teamid character varying(26),
    triggerwords character varying(1024),
    callbackurls character varying(1024),
    displayname character varying(64),
    contenttype character varying(128),
    triggerwhen integer,
    username character varying(64),
    iconurl character varying(1024),
    description character varying(500)
);


ALTER TABLE public.outgoingwebhooks OWNER TO mattermost_user;

--
-- Name: persistentnotifications; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.persistentnotifications (
    postid character varying(26) NOT NULL,
    createat bigint,
    lastsentat bigint,
    deleteat bigint,
    sentcount smallint
);


ALTER TABLE public.persistentnotifications OWNER TO mattermost_user;

--
-- Name: pluginkeyvaluestore; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.pluginkeyvaluestore (
    pluginid character varying(190) NOT NULL,
    pkey character varying(150) NOT NULL,
    pvalue bytea,
    expireat bigint
);


ALTER TABLE public.pluginkeyvaluestore OWNER TO mattermost_user;

--
-- Name: postacknowledgements; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.postacknowledgements (
    postid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    acknowledgedat bigint
);


ALTER TABLE public.postacknowledgements OWNER TO mattermost_user;

--
-- Name: postreminders; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.postreminders (
    postid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    targettime bigint
);


ALTER TABLE public.postreminders OWNER TO mattermost_user;

--
-- Name: posts; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.posts (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    userid character varying(26),
    channelid character varying(26),
    rootid character varying(26),
    originalid character varying(26),
    message character varying(65535),
    type character varying(26),
    props jsonb,
    hashtags character varying(1000),
    filenames character varying(4000),
    fileids character varying(300),
    hasreactions boolean,
    editat bigint,
    ispinned boolean,
    remoteid character varying(26)
)
WITH (autovacuum_vacuum_scale_factor='0.1', autovacuum_analyze_scale_factor='0.05');


ALTER TABLE public.posts OWNER TO mattermost_user;

--
-- Name: postspriority; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.postspriority (
    postid character varying(26) NOT NULL,
    channelid character varying(26) NOT NULL,
    priority character varying(32) NOT NULL,
    requestedack boolean,
    persistentnotifications boolean
);


ALTER TABLE public.postspriority OWNER TO mattermost_user;

--
-- Name: poststats; Type: MATERIALIZED VIEW; Schema: public; Owner: mattermost_user
--

CREATE MATERIALIZED VIEW public.poststats AS
 SELECT userid,
    (to_timestamp(((createat / 1000))::double precision))::date AS day,
    count(*) AS numposts,
    max(createat) AS lastpostdate
   FROM public.posts
  GROUP BY userid, ((to_timestamp(((createat / 1000))::double precision))::date)
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.poststats OWNER TO mattermost_user;

--
-- Name: preferences; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.preferences (
    userid character varying(26) NOT NULL,
    category character varying(32) NOT NULL,
    name character varying(32) NOT NULL,
    value text
)
WITH (autovacuum_vacuum_scale_factor='0.1', autovacuum_analyze_scale_factor='0.05');


ALTER TABLE public.preferences OWNER TO mattermost_user;

--
-- Name: productnoticeviewstate; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.productnoticeviewstate (
    userid character varying(26) NOT NULL,
    noticeid character varying(26) NOT NULL,
    viewed integer,
    "timestamp" bigint
);


ALTER TABLE public.productnoticeviewstate OWNER TO mattermost_user;

--
-- Name: propertyfields; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.propertyfields (
    id character varying(26) NOT NULL,
    groupid character varying(26) NOT NULL,
    name character varying(255) NOT NULL,
    type public.property_field_type,
    attrs jsonb,
    targetid character varying(255),
    targettype character varying(255),
    createat bigint NOT NULL,
    updateat bigint NOT NULL,
    deleteat bigint NOT NULL
);


ALTER TABLE public.propertyfields OWNER TO mattermost_user;

--
-- Name: propertygroups; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.propertygroups (
    id character varying(26) NOT NULL,
    name character varying(64) NOT NULL
);


ALTER TABLE public.propertygroups OWNER TO mattermost_user;

--
-- Name: propertyvalues; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.propertyvalues (
    id character varying(26) NOT NULL,
    targetid character varying(255) NOT NULL,
    targettype character varying(255) NOT NULL,
    groupid character varying(26) NOT NULL,
    fieldid character varying(26) NOT NULL,
    value jsonb NOT NULL,
    createat bigint NOT NULL,
    updateat bigint NOT NULL,
    deleteat bigint NOT NULL
);


ALTER TABLE public.propertyvalues OWNER TO mattermost_user;

--
-- Name: publicchannels; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.publicchannels (
    id character varying(26) NOT NULL,
    deleteat bigint,
    teamid character varying(26),
    displayname character varying(64),
    name character varying(64),
    header character varying(1024),
    purpose character varying(250)
);


ALTER TABLE public.publicchannels OWNER TO mattermost_user;

--
-- Name: reactions; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.reactions (
    userid character varying(26) NOT NULL,
    postid character varying(26) NOT NULL,
    emojiname character varying(64) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    remoteid character varying(26),
    channelid character varying(26) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.reactions OWNER TO mattermost_user;

--
-- Name: recentsearches; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.recentsearches (
    userid character(26) NOT NULL,
    searchpointer integer NOT NULL,
    query jsonb,
    createat bigint NOT NULL
);


ALTER TABLE public.recentsearches OWNER TO mattermost_user;

--
-- Name: remoteclusters; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.remoteclusters (
    remoteid character varying(26) NOT NULL,
    remoteteamid character varying(26),
    name character varying(64) NOT NULL,
    displayname character varying(64),
    siteurl character varying(512),
    createat bigint,
    lastpingat bigint,
    token character varying(26),
    remotetoken character varying(26),
    topics character varying(512),
    creatorid character varying(26),
    pluginid character varying(190) DEFAULT ''::character varying NOT NULL,
    options smallint DEFAULT 0 NOT NULL,
    defaultteamid character varying(26) DEFAULT ''::character varying,
    deleteat bigint DEFAULT 0
);


ALTER TABLE public.remoteclusters OWNER TO mattermost_user;

--
-- Name: retentionidsfordeletion; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.retentionidsfordeletion (
    id character varying(26) NOT NULL,
    tablename character varying(64),
    ids character varying(26)[]
);


ALTER TABLE public.retentionidsfordeletion OWNER TO mattermost_user;

--
-- Name: retentionpolicies; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.retentionpolicies (
    id character varying(26) NOT NULL,
    displayname character varying(64),
    postduration bigint
);


ALTER TABLE public.retentionpolicies OWNER TO mattermost_user;

--
-- Name: retentionpolicieschannels; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.retentionpolicieschannels (
    policyid character varying(26),
    channelid character varying(26) NOT NULL
);


ALTER TABLE public.retentionpolicieschannels OWNER TO mattermost_user;

--
-- Name: retentionpoliciesteams; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.retentionpoliciesteams (
    policyid character varying(26),
    teamid character varying(26) NOT NULL
);


ALTER TABLE public.retentionpoliciesteams OWNER TO mattermost_user;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.roles (
    id character varying(26) NOT NULL,
    name character varying(64),
    displayname character varying(128),
    description character varying(1024),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    permissions text,
    schememanaged boolean,
    builtin boolean
);


ALTER TABLE public.roles OWNER TO mattermost_user;

--
-- Name: scheduledposts; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.scheduledposts (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    userid character varying(26) NOT NULL,
    channelid character varying(26) NOT NULL,
    rootid character varying(26),
    message character varying(65535),
    props character varying(8000),
    fileids character varying(300),
    priority text,
    scheduledat bigint NOT NULL,
    processedat bigint,
    errorcode character varying(200)
);


ALTER TABLE public.scheduledposts OWNER TO mattermost_user;

--
-- Name: schemes; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.schemes (
    id character varying(26) NOT NULL,
    name character varying(64),
    displayname character varying(128),
    description character varying(1024),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    scope character varying(32),
    defaultteamadminrole character varying(64),
    defaultteamuserrole character varying(64),
    defaultchanneladminrole character varying(64),
    defaultchanneluserrole character varying(64),
    defaultteamguestrole character varying(64),
    defaultchannelguestrole character varying(64),
    defaultplaybookadminrole character varying(64) DEFAULT ''::character varying,
    defaultplaybookmemberrole character varying(64) DEFAULT ''::character varying,
    defaultrunadminrole character varying(64) DEFAULT ''::character varying,
    defaultrunmemberrole character varying(64) DEFAULT ''::character varying
);


ALTER TABLE public.schemes OWNER TO mattermost_user;

--
-- Name: sessions; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.sessions (
    id character varying(26) NOT NULL,
    token character varying(26),
    createat bigint,
    expiresat bigint,
    lastactivityat bigint,
    userid character varying(26),
    deviceid character varying(512),
    roles character varying(256),
    isoauth boolean,
    props jsonb,
    expirednotify boolean
);


ALTER TABLE public.sessions OWNER TO mattermost_user;

--
-- Name: sharedchannelattachments; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.sharedchannelattachments (
    id character varying(26) NOT NULL,
    fileid character varying(26),
    remoteid character varying(26),
    createat bigint,
    lastsyncat bigint
);


ALTER TABLE public.sharedchannelattachments OWNER TO mattermost_user;

--
-- Name: sharedchannelremotes; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.sharedchannelremotes (
    id character varying(26) NOT NULL,
    channelid character varying(26) NOT NULL,
    creatorid character varying(26),
    createat bigint,
    updateat bigint,
    isinviteaccepted boolean,
    isinviteconfirmed boolean,
    remoteid character varying(26),
    lastpostupdateat bigint,
    lastpostid character varying(26),
    lastpostcreateat bigint DEFAULT 0 NOT NULL,
    lastpostcreateid character varying(26),
    deleteat bigint DEFAULT 0
);


ALTER TABLE public.sharedchannelremotes OWNER TO mattermost_user;

--
-- Name: sharedchannels; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.sharedchannels (
    channelid character varying(26) NOT NULL,
    teamid character varying(26),
    home boolean,
    readonly boolean,
    sharename character varying(64),
    sharedisplayname character varying(64),
    sharepurpose character varying(250),
    shareheader character varying(1024),
    creatorid character varying(26),
    createat bigint,
    updateat bigint,
    remoteid character varying(26)
);


ALTER TABLE public.sharedchannels OWNER TO mattermost_user;

--
-- Name: sharedchannelusers; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.sharedchannelusers (
    id character varying(26) NOT NULL,
    userid character varying(26),
    remoteid character varying(26),
    createat bigint,
    lastsyncat bigint,
    channelid character varying(26)
);


ALTER TABLE public.sharedchannelusers OWNER TO mattermost_user;

--
-- Name: sidebarcategories; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.sidebarcategories (
    id character varying(128) NOT NULL,
    userid character varying(26),
    teamid character varying(26),
    sortorder bigint,
    sorting character varying(64),
    type character varying(64),
    displayname character varying(64),
    muted boolean,
    collapsed boolean
);


ALTER TABLE public.sidebarcategories OWNER TO mattermost_user;

--
-- Name: sidebarchannels; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.sidebarchannels (
    channelid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    categoryid character varying(128) NOT NULL,
    sortorder bigint
);


ALTER TABLE public.sidebarchannels OWNER TO mattermost_user;

--
-- Name: status; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.status (
    userid character varying(26) NOT NULL,
    status character varying(32),
    manual boolean,
    lastactivityat bigint,
    dndendtime bigint,
    prevstatus character varying(32)
);


ALTER TABLE public.status OWNER TO mattermost_user;

--
-- Name: systems; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.systems (
    name character varying(64) NOT NULL,
    value character varying(1024)
);


ALTER TABLE public.systems OWNER TO mattermost_user;

--
-- Name: teammembers; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.teammembers (
    teamid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    roles character varying(256),
    deleteat bigint,
    schemeuser boolean,
    schemeadmin boolean,
    schemeguest boolean,
    createat bigint DEFAULT 0
);


ALTER TABLE public.teammembers OWNER TO mattermost_user;

--
-- Name: teams; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.teams (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    displayname character varying(64),
    name character varying(64),
    description character varying(255),
    email character varying(128),
    type public.team_type,
    companyname character varying(64),
    alloweddomains character varying(1000),
    inviteid character varying(32),
    schemeid character varying(26),
    allowopeninvite boolean,
    lastteamiconupdate bigint,
    groupconstrained boolean,
    cloudlimitsarchived boolean DEFAULT false NOT NULL
);


ALTER TABLE public.teams OWNER TO mattermost_user;

--
-- Name: termsofservice; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.termsofservice (
    id character varying(26) NOT NULL,
    createat bigint,
    userid character varying(26),
    text character varying(65535)
);


ALTER TABLE public.termsofservice OWNER TO mattermost_user;

--
-- Name: threadmemberships; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.threadmemberships (
    postid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    following boolean,
    lastviewed bigint,
    lastupdated bigint,
    unreadmentions bigint
)
WITH (autovacuum_vacuum_scale_factor='0.1', autovacuum_analyze_scale_factor='0.05');


ALTER TABLE public.threadmemberships OWNER TO mattermost_user;

--
-- Name: threads; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.threads (
    postid character varying(26) NOT NULL,
    replycount bigint,
    lastreplyat bigint,
    participants jsonb,
    channelid character varying(26),
    threaddeleteat bigint,
    threadteamid character varying(26)
);


ALTER TABLE public.threads OWNER TO mattermost_user;

--
-- Name: tokens; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.tokens (
    token character varying(64) NOT NULL,
    createat bigint,
    type character varying(64),
    extra character varying(2048)
);


ALTER TABLE public.tokens OWNER TO mattermost_user;

--
-- Name: uploadsessions; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.uploadsessions (
    id character varying(26) NOT NULL,
    type public.upload_session_type,
    createat bigint,
    userid character varying(26),
    channelid character varying(26),
    filename character varying(256),
    path character varying(512),
    filesize bigint,
    fileoffset bigint,
    remoteid character varying(26),
    reqfileid character varying(26)
);


ALTER TABLE public.uploadsessions OWNER TO mattermost_user;

--
-- Name: useraccesstokens; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.useraccesstokens (
    id character varying(26) NOT NULL,
    token character varying(26),
    userid character varying(26),
    description character varying(512),
    isactive boolean
);


ALTER TABLE public.useraccesstokens OWNER TO mattermost_user;

--
-- Name: usergroups; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.usergroups (
    id character varying(26) NOT NULL,
    name character varying(64),
    displayname character varying(128),
    description character varying(1024),
    source character varying(64),
    remoteid character varying(48),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    allowreference boolean
);


ALTER TABLE public.usergroups OWNER TO mattermost_user;

--
-- Name: users; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.users (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    username character varying(64),
    password character varying(128),
    authdata character varying(128),
    authservice character varying(32),
    email character varying(128),
    emailverified boolean,
    nickname character varying(64),
    firstname character varying(64),
    lastname character varying(64),
    roles character varying(256),
    allowmarketing boolean,
    props jsonb,
    notifyprops jsonb,
    lastpasswordupdate bigint,
    lastpictureupdate bigint,
    failedattempts integer,
    locale character varying(5),
    mfaactive boolean,
    mfasecret character varying(128),
    "position" character varying(128),
    timezone jsonb,
    remoteid character varying(26),
    lastlogin bigint DEFAULT 0 NOT NULL,
    mfausedtimestamps jsonb
);


ALTER TABLE public.users OWNER TO mattermost_user;

--
-- Name: usertermsofservice; Type: TABLE; Schema: public; Owner: mattermost_user
--

CREATE TABLE public.usertermsofservice (
    userid character varying(26) NOT NULL,
    termsofserviceid character varying(26),
    createat bigint
);


ALTER TABLE public.usertermsofservice OWNER TO mattermost_user;

--
-- Data for Name: audits; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.audits (id, createat, userid, action, extrainfo, ipaddress, sessionid) FROM stdin;
ckrpm5565jbnpgrnhpzaip1r4h	1769537495434		/api/v4/users/ctz5686fy7fe5r3kfp8ckhp5yw/roles	user=ctz5686fy7fe5r3kfp8ckhp5yw roles=system_user system_admin		
58ue184h8pruzpskgzi3owgyjo	1769537495845		/api/v4/users/ctz5686fy7fe5r3kfp8ckhp5yw/password	attempted		
61figgg6jjdx3bz1p16ji1ukoh	1769537495912		/api/v4/users/ctz5686fy7fe5r3kfp8ckhp5yw/password	completed		
ab4g34wj6i8ozxwaxtfifa967o	1769537497842		/api/v4/users/arf1sprce7nq3qnjh1hsac91nw/password	attempted		
zkx4hfagkp8k3g8bt3i1bkyyde	1769537497906		/api/v4/users/arf1sprce7nq3qnjh1hsac91nw/password	completed		
mazxk78e578dmexqtqeif4sgue	1769537500154		/api/v4/users/gud7udwfobn3pnu8x81ef7rxna/password	attempted		
xcpscrn5w38qpx67ne4db8df9c	1769537500220		/api/v4/users/gud7udwfobn3pnu8x81ef7rxna/password	completed		
nhkfy6xkobg9ixe5jo5t9bu8hy	1769537502031		/api/v4/users/6zwwofjeipryzeon9xpnuq84xy/password	attempted		
9xaufsb1uinrbypk648ws5dw1c	1769537502107		/api/v4/users/6zwwofjeipryzeon9xpnuq84xy/password	completed		
jerojn8grfr77fzh43d4y399dh	1769537503907		/api/v4/users/jueqmzyedbruppmb8u956ykphe/password	attempted		
wkne66tuk7gsxrte1fjbbe5w7o	1769537503975		/api/v4/users/jueqmzyedbruppmb8u956ykphe/password	completed		
d5zfbrk5jtdstgixsqt8qaguow	1769537505736		/api/v4/users/ba1chd3qnprj5jx1tw6goqy4iy/password	attempted		
n7pc4mneqino9gtn9bbu6h593a	1769537505803		/api/v4/users/ba1chd3qnprj5jx1tw6goqy4iy/password	completed		
pzkpofd7zf8n9mkxygzy6a7bqr	1769537507932		/api/v4/users/j4i1gcm7stni8cqyhqixaexejw/password	attempted		
xc6853eypbbwdezty7c9nn1q5o	1769537507996		/api/v4/users/j4i1gcm7stni8cqyhqixaexejw/password	completed		
7iuigrje8inzbp6fq7thqfdaxc	1769537510111		/api/v4/users/7kzaisytntgidxic4jfr1yrg3y/password	attempted		
dg78f9ktufypufyfge166kpg5h	1769537510175		/api/v4/users/7kzaisytntgidxic4jfr1yrg3y/password	completed		
f7u8d6j6dibt5ep1radzuacn6r	1769537512445		/api/v4/users/4d5pwx1uob8gdmgqmc3fs9hfpe/password	attempted		
oejjwr6d33bsxbdkey8ttr6tmw	1769537512509		/api/v4/users/4d5pwx1uob8gdmgqmc3fs9hfpe/password	completed		
xwew1tof57gy5pfwpewoudwkfo	1769537514362		/api/v4/users/3a17zh894jrgbpw9ixhpjsyc9h/password	attempted		
atxcrrttjtyxiep5qhabpuh64e	1769537514427		/api/v4/users/3a17zh894jrgbpw9ixhpjsyc9h/password	completed		
abdxbn9tr3rfdgexucmzxcnr6w	1769537516201		/api/v4/users/eeif4rm7q3rrig6u1qkcusw35h/password	attempted		
uuk9ok8afj8i7bipz9zaz18fkw	1769537516265		/api/v4/users/eeif4rm7q3rrig6u1qkcusw35h/password	completed		
zcrjwxegjigmmxuktdkyyjazeo	1769537518388		/api/v4/users/q61z1nffcjbr9p1uf8zjyimqgr/password	attempted		
nnkjt11whbnwdbqgqowtocgzmr	1769537518452		/api/v4/users/q61z1nffcjbr9p1uf8zjyimqgr/password	completed		
jxfmtog3affc3rm1i39q7tmjxh	1769537520590		/api/v4/users/dr6nhfmd4iyp5dhfkkd1b1fy1h/password	attempted		
rchw6jghwpnn3rc57gbfa999hc	1769537520653		/api/v4/users/dr6nhfmd4iyp5dhfkkd1b1fy1h/password	completed		
i1p3drsscibbtej3secbz8915a	1769537527117		/api/v4/users/1w1w87fzdin5fpdta4ra8h5opw/roles	user=1w1w87fzdin5fpdta4ra8h5opw roles=system_user system_admin		
4naho4b1zfbwtpfrip6xa1ip4y	1769537527468		/api/v4/users/1w1w87fzdin5fpdta4ra8h5opw/password	attempted		
4r77x4x9rincbpucuqzmgiqpca	1769537527532		/api/v4/users/1w1w87fzdin5fpdta4ra8h5opw/password	completed		
ggbjimuqoirspxtfss55ekgnth	1771642478589		/api/v4/users/ctz5686fy7fe5r3kfp8ckhp5yw/password	attempted		
98cxam6kmpfdifcns9qdjmpxbh	1771642478648		/api/v4/users/ctz5686fy7fe5r3kfp8ckhp5yw/password	completed		
coyio4s867y8dfrap1uks4oq3r	1771642480856		/api/v4/users/arf1sprce7nq3qnjh1hsac91nw/password	attempted		
itrkc7sc1tg53co44ooetqgp7e	1771642480918		/api/v4/users/arf1sprce7nq3qnjh1hsac91nw/password	completed		
7fwfugwzt3rgtrqr4y3qcm7fnw	1771642483434		/api/v4/users/gud7udwfobn3pnu8x81ef7rxna/password	attempted		
xfuawftnt3nedme7wacyagahee	1771642483493		/api/v4/users/gud7udwfobn3pnu8x81ef7rxna/password	completed		
n5eaioybbbypmea46sns1u88tr	1771642485647		/api/v4/users/6zwwofjeipryzeon9xpnuq84xy/password	attempted		
gg98quex6ir1xede4zb8twegzy	1771642485708		/api/v4/users/6zwwofjeipryzeon9xpnuq84xy/password	completed		
3183cef9qiytumcqgdyzubr51o	1771642487892		/api/v4/users/jueqmzyedbruppmb8u956ykphe/password	attempted		
4khhw79sk7ggb8onm44784knxy	1771642487951		/api/v4/users/jueqmzyedbruppmb8u956ykphe/password	completed		
mcocqhsopfd3mryoixrcrpj6oy	1771642490074		/api/v4/users/ba1chd3qnprj5jx1tw6goqy4iy/password	attempted		
btn74najcigdxpcpts7gguddah	1771642490131		/api/v4/users/ba1chd3qnprj5jx1tw6goqy4iy/password	completed		
k61ox6xo57fbzdj6bs1mrz3shr	1771642492565		/api/v4/users/j4i1gcm7stni8cqyhqixaexejw/password	attempted		
yjiykc6kzfrhbyg9etbpeph89c	1771642492621		/api/v4/users/j4i1gcm7stni8cqyhqixaexejw/password	completed		
7suob9y9m3rmfy3gks9oz93hyo	1771642495107		/api/v4/users/7kzaisytntgidxic4jfr1yrg3y/password	attempted		
x4xhqttyu3rttdj3qg8s9mqguh	1771642495168		/api/v4/users/7kzaisytntgidxic4jfr1yrg3y/password	completed		
qdiwmocmo7yo9c4x8nrgruk7je	1771642497590		/api/v4/users/4d5pwx1uob8gdmgqmc3fs9hfpe/password	attempted		
acefa8h7ajg9ikhhe6rft6cuea	1771642497646		/api/v4/users/4d5pwx1uob8gdmgqmc3fs9hfpe/password	completed		
ktdq3xou8bg8zrqnr53wsx5efw	1771642499803		/api/v4/users/3a17zh894jrgbpw9ixhpjsyc9h/password	attempted		
g1ab63objbyadkg3infdigrjxh	1771642499861		/api/v4/users/3a17zh894jrgbpw9ixhpjsyc9h/password	completed		
uio4bbc39jr7jrxx8sh5ofsbpr	1771642502018		/api/v4/users/eeif4rm7q3rrig6u1qkcusw35h/password	attempted		
augzpkt3q7dxiqk61jnfgfkajo	1771642502078		/api/v4/users/eeif4rm7q3rrig6u1qkcusw35h/password	completed		
eqiuumnuybfyiecer9f3xbh81c	1771642504576		/api/v4/users/q61z1nffcjbr9p1uf8zjyimqgr/password	attempted		
hamgmhjo6igjdm13fni33x3dzo	1771642504636		/api/v4/users/q61z1nffcjbr9p1uf8zjyimqgr/password	completed		
ebjt6ioh7p8wpru1cqo3jspkac	1771642507154		/api/v4/users/dr6nhfmd4iyp5dhfkkd1b1fy1h/password	attempted		
6ins7f15jibhtmimo3axage8py	1771642507214		/api/v4/users/dr6nhfmd4iyp5dhfkkd1b1fy1h/password	completed		
qnsp8pisxjgxjpsbewz7yhdcgy	1771642509428		/api/v4/users/1w1w87fzdin5fpdta4ra8h5opw/password	attempted		
briwpoyh8jncjdg6ftnmdpj9qo	1771642509489		/api/v4/users/1w1w87fzdin5fpdta4ra8h5opw/password	completed		
nmichctqnbrw8d6p5t85j8fopa	1771646035638		/api/v4/users/ctz5686fy7fe5r3kfp8ckhp5yw/password	attempted		
eatj9gxnqp8k9q6uzap4bhf1gh	1771646035698		/api/v4/users/ctz5686fy7fe5r3kfp8ckhp5yw/password	completed		
onej3a7i67ymmm8tzto9c3miuc	1771646037841		/api/v4/users/arf1sprce7nq3qnjh1hsac91nw/password	attempted		
zj5jt8bjs7yfmbezoq5iwqwz1e	1771646037896		/api/v4/users/arf1sprce7nq3qnjh1hsac91nw/password	completed		
3mgr9rnre78a5nur3bcwbhruzo	1771646042587		/api/v4/users/6zwwofjeipryzeon9xpnuq84xy/password	attempted		
j1617ystxpdk9gtzqy5jrpokmr	1771646042644		/api/v4/users/6zwwofjeipryzeon9xpnuq84xy/password	completed		
sodyzxocoifa8rmbpsggypeppw	1771646044805		/api/v4/users/jueqmzyedbruppmb8u956ykphe/password	attempted		
rinxsmxwxfn5upoa833q1ou8xy	1771646044861		/api/v4/users/jueqmzyedbruppmb8u956ykphe/password	completed		
5gakodzopbfbxc57dh4z37du9c	1771646047016		/api/v4/users/ba1chd3qnprj5jx1tw6goqy4iy/password	attempted		
dmydsabkyjyf3yboperee9mzma	1771646047071		/api/v4/users/ba1chd3qnprj5jx1tw6goqy4iy/password	completed		
7fp4g61ty7y9jrybgsqjzebuno	1771646049513		/api/v4/users/j4i1gcm7stni8cqyhqixaexejw/password	attempted		
rch69tpruf8j5fbyd9qng9ucwy	1771646049574		/api/v4/users/j4i1gcm7stni8cqyhqixaexejw/password	completed		
77zr5d48wirj38ruy98mcda76h	1771646052033		/api/v4/users/7kzaisytntgidxic4jfr1yrg3y/password	attempted		
rbgtdhagotn8prmexqn8f61kfw	1771646052093		/api/v4/users/7kzaisytntgidxic4jfr1yrg3y/password	completed		
jnizzqh19fdq9ymoz77wab9kty	1771646054594		/api/v4/users/4d5pwx1uob8gdmgqmc3fs9hfpe/password	attempted		
wx5zixf6jfyzucwmg8ofkmgumo	1771646054654		/api/v4/users/4d5pwx1uob8gdmgqmc3fs9hfpe/password	completed		
7f6x763jii8wbd6wy8zq69z4ny	1771646056798		/api/v4/users/3a17zh894jrgbpw9ixhpjsyc9h/password	attempted		
jfc7oqca3ir3mre9k5mt7ecf5o	1771646056855		/api/v4/users/3a17zh894jrgbpw9ixhpjsyc9h/password	completed		
a8q3uhobntgxfq8jqofnnd5wqh	1771646061520		/api/v4/users/q61z1nffcjbr9p1uf8zjyimqgr/password	attempted		
c8qqwi8yypnx8gu57k3d57z1dh	1771646061578		/api/v4/users/q61z1nffcjbr9p1uf8zjyimqgr/password	completed		
nrimcf68s3bpbbaber9ku4esyy	1771646040364		/api/v4/users/gud7udwfobn3pnu8x81ef7rxna/password	attempted		
p4fnnx84z3gk7jwj6ijzq1wk3h	1771646040420		/api/v4/users/gud7udwfobn3pnu8x81ef7rxna/password	completed		
pje3ycqi93dc9n1g3ap7whyuya	1771646058996		/api/v4/users/eeif4rm7q3rrig6u1qkcusw35h/password	attempted		
3rgbdex1xpr5zgf517jqeegr3e	1771646059053		/api/v4/users/eeif4rm7q3rrig6u1qkcusw35h/password	completed		
xzkux3p4rjnyjrzcomdkn1fqea	1771646064052		/api/v4/users/dr6nhfmd4iyp5dhfkkd1b1fy1h/password	attempted		
ptxdttoqupyabkj8ez8o8sx1jw	1771646064107		/api/v4/users/dr6nhfmd4iyp5dhfkkd1b1fy1h/password	completed		
6kupyuiphjdqxkn4eohekfqd9o	1771646066268		/api/v4/users/1w1w87fzdin5fpdta4ra8h5opw/password	attempted		
m8u7txm4ztdbixkrhmxxa8rnzw	1771646066330		/api/v4/users/1w1w87fzdin5fpdta4ra8h5opw/password	completed		
\.


--
-- Data for Name: bots; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.bots (userid, description, ownerid, createat, updateat, deleteat, lasticonupdate) FROM stdin;
oi9jhtfswpbtbfotpsuuj71zuc	Playbooks bot.	playbooks	1769537460526	1769537460526	0	0
dyt7tnqg8p8mxqnm3r417ikwtw	Feedbackbot collects user feedback to improve Mattermost. [Learn more](https://mattermost.com/pl/default-nps).	com.mattermost.nps	1769537462536	1769537462536	0	0
ij3wiur3kib8mnwfmwetxqyrzr	Calls Bot	com.mattermost.calls	1769537463252	1769537463252	0	0
osi5d4mhzjdt7qiza78d5i38sw		ctz5686fy7fe5r3kfp8ckhp5yw	1771642500004	1771642500004	0	0
\.


--
-- Data for Name: calls; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.calls (id, channelid, startat, endat, createat, deleteat, title, postid, threadid, ownerid, participants, stats, props) FROM stdin;
\.


--
-- Data for Name: calls_channels; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.calls_channels (channelid, enabled, props) FROM stdin;
\.


--
-- Data for Name: calls_jobs; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.calls_jobs (id, callid, type, creatorid, initat, startat, endat, props) FROM stdin;
\.


--
-- Data for Name: calls_sessions; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.calls_sessions (id, callid, userid, joinat, unmuted, raisedhand) FROM stdin;
\.


--
-- Data for Name: channelbookmarks; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.channelbookmarks (id, ownerid, channelid, fileinfoid, createat, updateat, deleteat, displayname, sortorder, linkurl, imageurl, emoji, type, originalid, parentid) FROM stdin;
\.


--
-- Data for Name: channelmemberhistory; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.channelmemberhistory (channelid, userid, jointime, leavetime) FROM stdin;
rz5riz8jkfru8ki13145gsq3fo	ctz5686fy7fe5r3kfp8ckhp5yw	1769537496269	\N
z4izaem3dif6i8h8imj3w8hmuy	ctz5686fy7fe5r3kfp8ckhp5yw	1769537496308	\N
rz5riz8jkfru8ki13145gsq3fo	arf1sprce7nq3qnjh1hsac91nw	1769537498271	\N
z4izaem3dif6i8h8imj3w8hmuy	arf1sprce7nq3qnjh1hsac91nw	1769537498277	\N
skboo5k3cfg4zqm8yb6m33rn9a	arf1sprce7nq3qnjh1hsac91nw	1769537498634	\N
wxt9f3xwg7gfmpuau7pugetm1o	arf1sprce7nq3qnjh1hsac91nw	1769537498643	\N
rz5riz8jkfru8ki13145gsq3fo	gud7udwfobn3pnu8x81ef7rxna	1769537500567	\N
z4izaem3dif6i8h8imj3w8hmuy	gud7udwfobn3pnu8x81ef7rxna	1769537500572	\N
rz5riz8jkfru8ki13145gsq3fo	6zwwofjeipryzeon9xpnuq84xy	1769537502456	\N
z4izaem3dif6i8h8imj3w8hmuy	6zwwofjeipryzeon9xpnuq84xy	1769537502461	\N
rz5riz8jkfru8ki13145gsq3fo	jueqmzyedbruppmb8u956ykphe	1769537504313	\N
z4izaem3dif6i8h8imj3w8hmuy	jueqmzyedbruppmb8u956ykphe	1769537504320	\N
rz5riz8jkfru8ki13145gsq3fo	ba1chd3qnprj5jx1tw6goqy4iy	1769537506146	\N
z4izaem3dif6i8h8imj3w8hmuy	ba1chd3qnprj5jx1tw6goqy4iy	1769537506152	\N
skboo5k3cfg4zqm8yb6m33rn9a	ba1chd3qnprj5jx1tw6goqy4iy	1769537506508	\N
wxt9f3xwg7gfmpuau7pugetm1o	ba1chd3qnprj5jx1tw6goqy4iy	1769537506516	\N
rz5riz8jkfru8ki13145gsq3fo	j4i1gcm7stni8cqyhqixaexejw	1769537508326	\N
z4izaem3dif6i8h8imj3w8hmuy	j4i1gcm7stni8cqyhqixaexejw	1769537508332	\N
skboo5k3cfg4zqm8yb6m33rn9a	j4i1gcm7stni8cqyhqixaexejw	1769537508660	\N
wxt9f3xwg7gfmpuau7pugetm1o	j4i1gcm7stni8cqyhqixaexejw	1769537508665	\N
rz5riz8jkfru8ki13145gsq3fo	7kzaisytntgidxic4jfr1yrg3y	1769537510552	\N
z4izaem3dif6i8h8imj3w8hmuy	7kzaisytntgidxic4jfr1yrg3y	1769537510561	\N
skboo5k3cfg4zqm8yb6m33rn9a	7kzaisytntgidxic4jfr1yrg3y	1769537510971	\N
wxt9f3xwg7gfmpuau7pugetm1o	7kzaisytntgidxic4jfr1yrg3y	1769537510988	\N
rz5riz8jkfru8ki13145gsq3fo	4d5pwx1uob8gdmgqmc3fs9hfpe	1769537512873	\N
z4izaem3dif6i8h8imj3w8hmuy	4d5pwx1uob8gdmgqmc3fs9hfpe	1769537512879	\N
rz5riz8jkfru8ki13145gsq3fo	3a17zh894jrgbpw9ixhpjsyc9h	1769537514775	\N
z4izaem3dif6i8h8imj3w8hmuy	3a17zh894jrgbpw9ixhpjsyc9h	1769537514784	\N
rz5riz8jkfru8ki13145gsq3fo	eeif4rm7q3rrig6u1qkcusw35h	1769537516615	\N
z4izaem3dif6i8h8imj3w8hmuy	eeif4rm7q3rrig6u1qkcusw35h	1769537516620	\N
skboo5k3cfg4zqm8yb6m33rn9a	eeif4rm7q3rrig6u1qkcusw35h	1769537516962	\N
wxt9f3xwg7gfmpuau7pugetm1o	eeif4rm7q3rrig6u1qkcusw35h	1769537516968	\N
rz5riz8jkfru8ki13145gsq3fo	q61z1nffcjbr9p1uf8zjyimqgr	1769537518777	\N
z4izaem3dif6i8h8imj3w8hmuy	q61z1nffcjbr9p1uf8zjyimqgr	1769537518783	\N
skboo5k3cfg4zqm8yb6m33rn9a	q61z1nffcjbr9p1uf8zjyimqgr	1769537519121	\N
wxt9f3xwg7gfmpuau7pugetm1o	q61z1nffcjbr9p1uf8zjyimqgr	1769537519127	\N
rz5riz8jkfru8ki13145gsq3fo	dr6nhfmd4iyp5dhfkkd1b1fy1h	1769537521013	\N
z4izaem3dif6i8h8imj3w8hmuy	dr6nhfmd4iyp5dhfkkd1b1fy1h	1769537521020	\N
rz5riz8jkfru8ki13145gsq3fo	1w1w87fzdin5fpdta4ra8h5opw	1769537527867	\N
z4izaem3dif6i8h8imj3w8hmuy	1w1w87fzdin5fpdta4ra8h5opw	1769537527874	\N
\.


--
-- Data for Name: channelmembers; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.channelmembers (channelid, userid, roles, lastviewedat, msgcount, mentioncount, notifyprops, lastupdateat, schemeuser, schemeadmin, schemeguest, mentioncountroot, msgcountroot, urgentmentioncount) FROM stdin;
rz5riz8jkfru8ki13145gsq3fo	q61z1nffcjbr9p1uf8zjyimqgr		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537518776	t	f	f	0	0	0
skboo5k3cfg4zqm8yb6m33rn9a	q61z1nffcjbr9p1uf8zjyimqgr		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537519119	t	f	f	0	0	0
z4izaem3dif6i8h8imj3w8hmuy	4d5pwx1uob8gdmgqmc3fs9hfpe		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537512877	t	f	f	0	0	0
z4izaem3dif6i8h8imj3w8hmuy	q61z1nffcjbr9p1uf8zjyimqgr		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537518781	t	f	f	0	0	0
rz5riz8jkfru8ki13145gsq3fo	1w1w87fzdin5fpdta4ra8h5opw		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537527866	t	f	f	0	0	0
rz5riz8jkfru8ki13145gsq3fo	3a17zh894jrgbpw9ixhpjsyc9h		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537514773	t	f	f	0	0	0
rz5riz8jkfru8ki13145gsq3fo	4d5pwx1uob8gdmgqmc3fs9hfpe		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537512871	t	f	f	0	0	0
rz5riz8jkfru8ki13145gsq3fo	6zwwofjeipryzeon9xpnuq84xy		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537502454	t	f	f	0	0	0
rz5riz8jkfru8ki13145gsq3fo	7kzaisytntgidxic4jfr1yrg3y		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537510550	t	f	f	0	0	0
rz5riz8jkfru8ki13145gsq3fo	arf1sprce7nq3qnjh1hsac91nw		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537498270	t	f	f	0	0	0
rz5riz8jkfru8ki13145gsq3fo	ba1chd3qnprj5jx1tw6goqy4iy		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537506145	t	f	f	0	0	0
rz5riz8jkfru8ki13145gsq3fo	ctz5686fy7fe5r3kfp8ckhp5yw		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537496265	t	f	f	0	0	0
rz5riz8jkfru8ki13145gsq3fo	dr6nhfmd4iyp5dhfkkd1b1fy1h		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537521011	t	f	f	0	0	0
rz5riz8jkfru8ki13145gsq3fo	eeif4rm7q3rrig6u1qkcusw35h		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537516613	t	f	f	0	0	0
rz5riz8jkfru8ki13145gsq3fo	gud7udwfobn3pnu8x81ef7rxna		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537500565	t	f	f	0	0	0
rz5riz8jkfru8ki13145gsq3fo	j4i1gcm7stni8cqyhqixaexejw		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537508324	t	f	f	0	0	0
rz5riz8jkfru8ki13145gsq3fo	jueqmzyedbruppmb8u956ykphe		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537504311	t	f	f	0	0	0
skboo5k3cfg4zqm8yb6m33rn9a	7kzaisytntgidxic4jfr1yrg3y		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537510964	t	f	f	0	0	0
skboo5k3cfg4zqm8yb6m33rn9a	arf1sprce7nq3qnjh1hsac91nw		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537498632	t	f	f	0	0	0
skboo5k3cfg4zqm8yb6m33rn9a	ba1chd3qnprj5jx1tw6goqy4iy		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537506506	t	f	f	0	0	0
skboo5k3cfg4zqm8yb6m33rn9a	eeif4rm7q3rrig6u1qkcusw35h		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537516960	t	f	f	0	0	0
skboo5k3cfg4zqm8yb6m33rn9a	j4i1gcm7stni8cqyhqixaexejw		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537508658	t	f	f	0	0	0
wxt9f3xwg7gfmpuau7pugetm1o	7kzaisytntgidxic4jfr1yrg3y		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537510984	t	f	f	0	0	0
wxt9f3xwg7gfmpuau7pugetm1o	arf1sprce7nq3qnjh1hsac91nw		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537498639	t	f	f	0	0	0
wxt9f3xwg7gfmpuau7pugetm1o	ba1chd3qnprj5jx1tw6goqy4iy		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537506512	t	f	f	0	0	0
wxt9f3xwg7gfmpuau7pugetm1o	eeif4rm7q3rrig6u1qkcusw35h		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537516966	t	f	f	0	0	0
wxt9f3xwg7gfmpuau7pugetm1o	j4i1gcm7stni8cqyhqixaexejw		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537508663	t	f	f	0	0	0
wxt9f3xwg7gfmpuau7pugetm1o	q61z1nffcjbr9p1uf8zjyimqgr		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537519125	t	f	f	0	0	0
z4izaem3dif6i8h8imj3w8hmuy	1w1w87fzdin5fpdta4ra8h5opw		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537527872	t	f	f	0	0	0
z4izaem3dif6i8h8imj3w8hmuy	3a17zh894jrgbpw9ixhpjsyc9h		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537514781	t	f	f	0	0	0
z4izaem3dif6i8h8imj3w8hmuy	6zwwofjeipryzeon9xpnuq84xy		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537502459	t	f	f	0	0	0
z4izaem3dif6i8h8imj3w8hmuy	7kzaisytntgidxic4jfr1yrg3y		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537510557	t	f	f	0	0	0
z4izaem3dif6i8h8imj3w8hmuy	arf1sprce7nq3qnjh1hsac91nw		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537498275	t	f	f	0	0	0
z4izaem3dif6i8h8imj3w8hmuy	ba1chd3qnprj5jx1tw6goqy4iy		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537506150	t	f	f	0	0	0
z4izaem3dif6i8h8imj3w8hmuy	ctz5686fy7fe5r3kfp8ckhp5yw		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537496299	t	f	f	0	0	0
z4izaem3dif6i8h8imj3w8hmuy	dr6nhfmd4iyp5dhfkkd1b1fy1h		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537521017	t	f	f	0	0	0
z4izaem3dif6i8h8imj3w8hmuy	eeif4rm7q3rrig6u1qkcusw35h		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537516619	t	f	f	0	0	0
z4izaem3dif6i8h8imj3w8hmuy	gud7udwfobn3pnu8x81ef7rxna		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537500570	t	f	f	0	0	0
z4izaem3dif6i8h8imj3w8hmuy	j4i1gcm7stni8cqyhqixaexejw		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537508329	t	f	f	0	0	0
z4izaem3dif6i8h8imj3w8hmuy	jueqmzyedbruppmb8u956ykphe		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1769537504317	t	f	f	0	0	0
\.


--
-- Data for Name: channels; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.channels (id, createat, updateat, deleteat, teamid, type, displayname, name, header, purpose, lastpostat, totalmsgcount, extraupdateat, creatorid, schemeid, groupconstrained, shared, totalmsgcountroot, lastrootpostat) FROM stdin;
skboo5k3cfg4zqm8yb6m33rn9a	1769537494969	1769537494969	0	nehyf6um5pfg7ejqkk4ccumroc	O	Town Square	town-square			1769537519122	0	0		\N	\N	\N	0	1769537519122
wxt9f3xwg7gfmpuau7pugetm1o	1769537494971	1769537494971	0	nehyf6um5pfg7ejqkk4ccumroc	O	Off-Topic	off-topic			1769537519127	0	0		\N	\N	\N	0	1769537519127
rz5riz8jkfru8ki13145gsq3fo	1769537494444	1769537494444	0	urj86b44zineig6jtetjez8qww	O	Town Square	town-square			1769537527868	0	0		\N	\N	\N	0	1769537527868
z4izaem3dif6i8h8imj3w8hmuy	1769537494489	1769537494489	0	urj86b44zineig6jtetjez8qww	O	Off-Topic	off-topic			1769537527875	0	0		\N	\N	\N	0	1769537527875
\.


--
-- Data for Name: clusterdiscovery; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.clusterdiscovery (id, type, clustername, hostname, gossipport, port, createat, lastpingat) FROM stdin;
\.


--
-- Data for Name: commands; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.commands (id, token, createat, updateat, deleteat, creatorid, teamid, trigger, method, username, iconurl, autocomplete, autocompletedesc, autocompletehint, displayname, description, url, pluginid) FROM stdin;
\.


--
-- Data for Name: commandwebhooks; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.commandwebhooks (id, createat, commandid, userid, channelid, rootid, usecount) FROM stdin;
\.


--
-- Data for Name: compliances; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.compliances (id, createat, userid, status, count, "desc", type, startat, endat, keywords, emails) FROM stdin;
\.


--
-- Data for Name: configurationfiles; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.configurationfiles (name, data, createat, updateat) FROM stdin;
\.


--
-- Data for Name: configurations; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.configurations (id, value, createat, active, sha) FROM stdin;
6b1qazsbjpdd9mrwzyp5gfrbzc	{\n    "ServiceSettings": {\n        "SiteURL": "",\n        "WebsocketURL": "",\n        "LicenseFileLocation": "",\n        "ListenAddress": ":8065",\n        "ConnectionSecurity": "",\n        "TLSCertFile": "",\n        "TLSKeyFile": "",\n        "TLSMinVer": "1.2",\n        "TLSStrictTransport": false,\n        "TLSStrictTransportMaxAge": 63072000,\n        "TLSOverwriteCiphers": [],\n        "UseLetsEncrypt": false,\n        "LetsEncryptCertificateCacheFile": "./config/letsencrypt.cache",\n        "Forward80To443": false,\n        "TrustedProxyIPHeader": [],\n        "ReadTimeout": 300,\n        "WriteTimeout": 300,\n        "IdleTimeout": 60,\n        "MaximumLoginAttempts": 10,\n        "GoroutineHealthThreshold": -1,\n        "EnableOAuthServiceProvider": true,\n        "EnableIncomingWebhooks": true,\n        "EnableOutgoingWebhooks": true,\n        "EnableOutgoingOAuthConnections": false,\n        "EnableCommands": true,\n        "OutgoingIntegrationRequestsTimeout": 30,\n        "EnablePostUsernameOverride": false,\n        "EnablePostIconOverride": false,\n        "GoogleDeveloperKey": "",\n        "EnableLinkPreviews": true,\n        "EnablePermalinkPreviews": true,\n        "RestrictLinkPreviews": "",\n        "EnableTesting": false,\n        "EnableDeveloper": false,\n        "DeveloperFlags": "",\n        "EnableClientPerformanceDebugging": false,\n        "EnableOpenTracing": false,\n        "EnableSecurityFixAlert": true,\n        "EnableInsecureOutgoingConnections": false,\n        "AllowedUntrustedInternalConnections": "",\n        "EnableMultifactorAuthentication": false,\n        "EnforceMultifactorAuthentication": false,\n        "EnableUserAccessTokens": false,\n        "AllowCorsFrom": "",\n        "CorsExposedHeaders": "",\n        "CorsAllowCredentials": false,\n        "CorsDebug": false,\n        "AllowCookiesForSubdomains": false,\n        "ExtendSessionLengthWithActivity": false,\n        "TerminateSessionsOnPasswordChange": false,\n        "SessionLengthWebInDays": 180,\n        "SessionLengthWebInHours": 4320,\n        "SessionLengthMobileInDays": 180,\n        "SessionLengthMobileInHours": 4320,\n        "SessionLengthSSOInDays": 30,\n        "SessionLengthSSOInHours": 720,\n        "SessionCacheInMinutes": 10,\n        "SessionIdleTimeoutInMinutes": 43200,\n        "WebsocketSecurePort": 443,\n        "WebsocketPort": 80,\n        "WebserverMode": "gzip",\n        "EnableGifPicker": true,\n        "GiphySdkKey": "",\n        "EnableCustomEmoji": true,\n        "EnableEmojiPicker": true,\n        "PostEditTimeLimit": -1,\n        "TimeBetweenUserTypingUpdatesMilliseconds": 5000,\n        "EnablePostSearch": true,\n        "EnableFileSearch": true,\n        "MinimumHashtagLength": 3,\n        "EnableUserTypingMessages": true,\n        "EnableChannelViewedMessages": true,\n        "EnableUserStatuses": true,\n        "ExperimentalEnableAuthenticationTransfer": true,\n        "ClusterLogTimeoutMilliseconds": 2000,\n        "EnableTutorial": true,\n        "EnableOnboardingFlow": true,\n        "ExperimentalEnableDefaultChannelLeaveJoinMessages": true,\n        "ExperimentalGroupUnreadChannels": "disabled",\n        "EnableAPITeamDeletion": false,\n        "EnableAPITriggerAdminNotifications": false,\n        "EnableAPIUserDeletion": false,\n        "EnableAPIPostDeletion": false,\n        "EnableDesktopLandingPage": true,\n        "ExperimentalEnableHardenedMode": false,\n        "ExperimentalStrictCSRFEnforcement": false,\n        "EnableEmailInvitations": true,\n        "DisableBotsWhenOwnerIsDeactivated": true,\n        "EnableBotAccountCreation": false,\n        "EnableSVGs": true,\n        "EnableLatex": true,\n        "EnableInlineLatex": true,\n        "PostPriority": true,\n        "AllowPersistentNotifications": true,\n        "AllowPersistentNotificationsForGuests": false,\n        "PersistentNotificationIntervalMinutes": 5,\n        "PersistentNotificationMaxCount": 6,\n        "PersistentNotificationMaxRecipients": 5,\n        "EnableAPIChannelDeletion": false,\n        "EnableLocalMode": false,\n        "LocalModeSocketLocation": "/var/tmp/mattermost_local.socket",\n        "EnableAWSMetering": false,\n        "SplitKey": "",\n        "FeatureFlagSyncIntervalSeconds": 30,\n        "DebugSplit": false,\n        "ThreadAutoFollow": true,\n        "CollapsedThreads": "always_on",\n        "ManagedResourcePaths": "",\n        "EnableCustomGroups": true,\n        "AllowSyncedDrafts": true,\n        "UniqueEmojiReactionLimitPerPost": 50,\n        "RefreshPostStatsRunTime": "00:00",\n        "MaximumPayloadSizeBytes": 300000,\n        "MaximumURLLength": 2048,\n        "ScheduledPosts": true,\n        "EnableWebHubChannelIteration": false\n    },\n    "TeamSettings": {\n        "SiteName": "Mattermost",\n        "MaxUsersPerTeam": 50,\n        "EnableJoinLeaveMessageByDefault": true,\n        "EnableUserCreation": true,\n        "EnableOpenServer": false,\n        "EnableUserDeactivation": false,\n        "RestrictCreationToDomains": "",\n        "EnableCustomUserStatuses": true,\n        "EnableCustomBrand": false,\n        "CustomBrandText": "",\n        "CustomDescriptionText": "",\n        "RestrictDirectMessage": "any",\n        "EnableLastActiveTime": true,\n        "UserStatusAwayTimeout": 300,\n        "MaxChannelsPerTeam": 2000,\n        "MaxNotificationsPerChannel": 1000,\n        "EnableConfirmNotificationsToChannel": true,\n        "TeammateNameDisplay": "username",\n        "ExperimentalViewArchivedChannels": true,\n        "ExperimentalEnableAutomaticReplies": false,\n        "LockTeammateNameDisplay": false,\n        "ExperimentalPrimaryTeam": "",\n        "ExperimentalDefaultChannels": []\n    },\n    "ClientRequirements": {\n        "AndroidLatestVersion": "",\n        "AndroidMinVersion": "",\n        "IosLatestVersion": "",\n        "IosMinVersion": ""\n    },\n    "SqlSettings": {\n        "DriverName": "postgres",\n        "DataSource": "postgres://mattermost_user:mattermost_pw@postgres.zoo/mattermost_db?sslmode=disable",\n        "DataSourceReplicas": [],\n        "DataSourceSearchReplicas": [],\n        "MaxIdleConns": 20,\n        "ConnMaxLifetimeMilliseconds": 3600000,\n        "ConnMaxIdleTimeMilliseconds": 300000,\n        "MaxOpenConns": 300,\n        "Trace": false,\n        "AtRestEncryptKey": "51z7tarrgmz9wzcnt8rumnzkqsdukrxr",\n        "QueryTimeout": 30,\n        "DisableDatabaseSearch": false,\n        "MigrationsStatementTimeoutSeconds": 100000,\n        "ReplicaLagSettings": [],\n        "ReplicaMonitorIntervalSeconds": 5\n    },\n    "LogSettings": {\n        "EnableConsole": true,\n        "ConsoleLevel": "DEBUG",\n        "ConsoleJson": true,\n        "EnableColor": false,\n        "EnableFile": true,\n        "FileLevel": "INFO",\n        "FileJson": true,\n        "FileLocation": "",\n        "EnableWebhookDebugging": true,\n        "EnableDiagnostics": true,\n        "VerboseDiagnostics": false,\n        "EnableSentry": true,\n        "AdvancedLoggingJSON": null,\n        "MaxFieldSize": 2048\n    },\n    "ExperimentalAuditSettings": {\n        "FileEnabled": false,\n        "FileName": "",\n        "FileMaxSizeMB": 100,\n        "FileMaxAgeDays": 0,\n        "FileMaxBackups": 0,\n        "FileCompress": false,\n        "FileMaxQueueSize": 1000,\n        "AdvancedLoggingJSON": null\n    },\n    "NotificationLogSettings": {\n        "EnableConsole": true,\n        "ConsoleLevel": "DEBUG",\n        "ConsoleJson": true,\n        "EnableColor": false,\n        "EnableFile": true,\n        "FileLevel": "INFO",\n        "FileJson": true,\n        "FileLocation": "",\n        "AdvancedLoggingJSON": null\n    },\n    "PasswordSettings": {\n        "MinimumLength": 8,\n        "Lowercase": false,\n        "Number": false,\n        "Uppercase": false,\n        "Symbol": false,\n        "EnableForgotLink": true\n    },\n    "FileSettings": {\n        "EnableFileAttachments": true,\n        "EnableMobileUpload": true,\n        "EnableMobileDownload": true,\n        "MaxFileSize": 104857600,\n        "MaxImageResolution": 33177600,\n        "MaxImageDecoderConcurrency": -1,\n        "DriverName": "local",\n        "Directory": "./data/",\n        "EnablePublicLink": false,\n        "ExtractContent": true,\n        "ArchiveRecursion": false,\n        "PublicLinkSalt": "qteo68ysr89by8wjnarggb53tguak4eo",\n        "InitialFont": "nunito-bold.ttf",\n        "AmazonS3AccessKeyId": "",\n        "AmazonS3SecretAccessKey": "",\n        "AmazonS3Bucket": "",\n        "AmazonS3PathPrefix": "",\n        "AmazonS3Region": "",\n        "AmazonS3Endpoint": "s3.amazonaws.com",\n        "AmazonS3SSL": true,\n        "AmazonS3SignV2": false,\n        "AmazonS3SSE": false,\n        "AmazonS3Trace": false,\n        "AmazonS3RequestTimeoutMilliseconds": 30000,\n        "AmazonS3UploadPartSizeBytes": 5242880,\n        "AmazonS3StorageClass": "",\n        "DedicatedExportStore": false,\n        "ExportDriverName": "local",\n        "ExportDirectory": "./data/",\n        "ExportAmazonS3AccessKeyId": "",\n        "ExportAmazonS3SecretAccessKey": "",\n        "ExportAmazonS3Bucket": "",\n        "ExportAmazonS3PathPrefix": "",\n        "ExportAmazonS3Region": "",\n        "ExportAmazonS3Endpoint": "s3.amazonaws.com",\n        "ExportAmazonS3SSL": true,\n        "ExportAmazonS3SignV2": false,\n        "ExportAmazonS3SSE": false,\n        "ExportAmazonS3Trace": false,\n        "ExportAmazonS3RequestTimeoutMilliseconds": 30000,\n        "ExportAmazonS3PresignExpiresSeconds": 21600,\n        "ExportAmazonS3UploadPartSizeBytes": 104857600,\n        "ExportAmazonS3StorageClass": ""\n    },\n    "EmailSettings": {\n        "EnableSignUpWithEmail": true,\n        "EnableSignInWithEmail": true,\n        "EnableSignInWithUsername": true,\n        "SendEmailNotifications": true,\n        "UseChannelInEmailNotifications": false,\n        "RequireEmailVerification": false,\n        "FeedbackName": "",\n        "FeedbackEmail": "test@example.com",\n        "ReplyToAddress": "test@example.com",\n        "FeedbackOrganization": "",\n        "EnableSMTPAuth": false,\n        "SMTPUsername": "",\n        "SMTPPassword": "",\n        "SMTPServer": "localhost",\n        "SMTPPort": "10025",\n        "SMTPServerTimeout": 10,\n        "ConnectionSecurity": "",\n        "SendPushNotifications": false,\n        "PushNotificationServer": "",\n        "PushNotificationContents": "full",\n        "PushNotificationBuffer": 1000,\n        "EnableEmailBatching": false,\n        "EmailBatchingBufferSize": 256,\n        "EmailBatchingInterval": 30,\n        "EnablePreviewModeBanner": true,\n        "SkipServerCertificateVerification": false,\n        "EmailNotificationContentsType": "full",\n        "LoginButtonColor": "#0000",\n        "LoginButtonBorderColor": "#2389D7",\n        "LoginButtonTextColor": "#2389D7"\n    },\n    "RateLimitSettings": {\n        "Enable": false,\n        "PerSec": 10,\n        "MaxBurst": 100,\n        "MemoryStoreSize": 10000,\n        "VaryByRemoteAddr": true,\n        "VaryByUser": false,\n        "VaryByHeader": ""\n    },\n    "PrivacySettings": {\n        "ShowEmailAddress": true,\n        "ShowFullName": true\n    },\n    "SupportSettings": {\n        "TermsOfServiceLink": "https://mattermost.com/pl/terms-of-use/",\n        "PrivacyPolicyLink": "https://mattermost.com/pl/privacy-policy/",\n        "AboutLink": "https://mattermost.com/pl/about-mattermost",\n        "HelpLink": "https://mattermost.com/pl/help/",\n        "ReportAProblemLink": "https://mattermost.com/pl/report-a-bug",\n        "ForgotPasswordLink": "",\n        "SupportEmail": "",\n        "CustomTermsOfServiceEnabled": false,\n        "CustomTermsOfServiceReAcceptancePeriod": 365,\n        "EnableAskCommunityLink": true\n    },\n    "AnnouncementSettings": {\n        "EnableBanner": false,\n        "BannerText": "",\n        "BannerColor": "#f2a93b",\n        "BannerTextColor": "#333333",\n        "AllowBannerDismissal": true,\n        "AdminNoticesEnabled": true,\n        "UserNoticesEnabled": true,\n        "NoticesURL": "https://notices.mattermost.com/",\n        "NoticesFetchFrequency": 3600,\n        "NoticesSkipCache": false\n    },\n    "ThemeSettings": {\n        "EnableThemeSelection": true,\n        "DefaultTheme": "default",\n        "AllowCustomThemes": true,\n        "AllowedThemes": []\n    },\n    "GitLabSettings": {\n        "Enable": false,\n        "Secret": "",\n        "Id": "",\n        "Scope": "",\n        "AuthEndpoint": "",\n        "TokenEndpoint": "",\n        "UserAPIEndpoint": "",\n        "DiscoveryEndpoint": "",\n        "ButtonText": "",\n        "ButtonColor": ""\n    },\n    "GoogleSettings": {\n        "Enable": false,\n        "Secret": "",\n        "Id": "",\n        "Scope": "profile email",\n        "AuthEndpoint": "https://accounts.google.com/o/oauth2/v2/auth",\n        "TokenEndpoint": "https://www.googleapis.com/oauth2/v4/token",\n        "UserAPIEndpoint": "https://people.googleapis.com/v1/people/me?personFields=names,emailAddresses,nicknames,metadata",\n        "DiscoveryEndpoint": "",\n        "ButtonText": "",\n        "ButtonColor": ""\n    },\n    "Office365Settings": {\n        "Enable": false,\n        "Secret": "",\n        "Id": "",\n        "Scope": "User.Read",\n        "AuthEndpoint": "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",\n        "TokenEndpoint": "https://login.microsoftonline.com/common/oauth2/v2.0/token",\n        "UserAPIEndpoint": "https://graph.microsoft.com/v1.0/me",\n        "DiscoveryEndpoint": "",\n        "DirectoryId": ""\n    },\n    "OpenIdSettings": {\n        "Enable": false,\n        "Secret": "",\n        "Id": "",\n        "Scope": "profile openid email",\n        "AuthEndpoint": "",\n        "TokenEndpoint": "",\n        "UserAPIEndpoint": "",\n        "DiscoveryEndpoint": "",\n        "ButtonText": "",\n        "ButtonColor": "#145DBF"\n    },\n    "LdapSettings": {\n        "Enable": false,\n        "EnableSync": false,\n        "LdapServer": "",\n        "LdapPort": 389,\n        "ConnectionSecurity": "",\n        "BaseDN": "",\n        "BindUsername": "",\n        "BindPassword": "",\n        "MaximumLoginAttempts": 10,\n        "UserFilter": "",\n        "GroupFilter": "",\n        "GuestFilter": "",\n        "EnableAdminFilter": false,\n        "AdminFilter": "",\n        "GroupDisplayNameAttribute": "",\n        "GroupIdAttribute": "",\n        "FirstNameAttribute": "",\n        "LastNameAttribute": "",\n        "EmailAttribute": "",\n        "UsernameAttribute": "",\n        "NicknameAttribute": "",\n        "IdAttribute": "",\n        "PositionAttribute": "",\n        "LoginIdAttribute": "",\n        "PictureAttribute": "",\n        "SyncIntervalMinutes": 60,\n        "SkipCertificateVerification": false,\n        "PublicCertificateFile": "",\n        "PrivateKeyFile": "",\n        "QueryTimeout": 60,\n        "MaxPageSize": 0,\n        "LoginFieldName": "",\n        "LoginButtonColor": "#0000",\n        "LoginButtonBorderColor": "#2389D7",\n        "LoginButtonTextColor": "#2389D7"\n    },\n    "ComplianceSettings": {\n        "Enable": false,\n        "Directory": "./data/",\n        "EnableDaily": false,\n        "BatchSize": 30000\n    },\n    "LocalizationSettings": {\n        "DefaultServerLocale": "en",\n        "DefaultClientLocale": "en",\n        "AvailableLocales": "",\n        "EnableExperimentalLocales": false\n    },\n    "SamlSettings": {\n        "Enable": false,\n        "EnableSyncWithLdap": false,\n        "EnableSyncWithLdapIncludeAuth": false,\n        "IgnoreGuestsLdapSync": false,\n        "Verify": true,\n        "Encrypt": true,\n        "SignRequest": false,\n        "IdpURL": "",\n        "IdpDescriptorURL": "",\n        "IdpMetadataURL": "",\n        "ServiceProviderIdentifier": "",\n        "AssertionConsumerServiceURL": "",\n        "SignatureAlgorithm": "RSAwithSHA1",\n        "CanonicalAlgorithm": "Canonical1.0",\n        "ScopingIDPProviderId": "",\n        "ScopingIDPName": "",\n        "IdpCertificateFile": "",\n        "PublicCertificateFile": "",\n        "PrivateKeyFile": "",\n        "IdAttribute": "",\n        "GuestAttribute": "",\n        "EnableAdminAttribute": false,\n        "AdminAttribute": "",\n        "FirstNameAttribute": "",\n        "LastNameAttribute": "",\n        "EmailAttribute": "",\n        "UsernameAttribute": "",\n        "NicknameAttribute": "",\n        "LocaleAttribute": "",\n        "PositionAttribute": "",\n        "LoginButtonText": "SAML",\n        "LoginButtonColor": "#34a28b",\n        "LoginButtonBorderColor": "#2389D7",\n        "LoginButtonTextColor": "#ffffff"\n    },\n    "NativeAppSettings": {\n        "AppCustomURLSchemes": [\n            "mmauth://",\n            "mmauthbeta://"\n        ],\n        "AppDownloadLink": "https://mattermost.com/pl/download-apps",\n        "AndroidAppDownloadLink": "https://mattermost.com/pl/android-app/",\n        "IosAppDownloadLink": "https://mattermost.com/pl/ios-app/",\n        "MobileExternalBrowser": false\n    },\n    "CacheSettings": {\n        "CacheType": "lru",\n        "RedisAddress": "",\n        "RedisPassword": "",\n        "RedisDB": -1,\n        "DisableClientCache": false\n    },\n    "ClusterSettings": {\n        "Enable": false,\n        "ClusterName": "",\n        "OverrideHostname": "",\n        "NetworkInterface": "",\n        "BindAddress": "",\n        "AdvertiseAddress": "",\n        "UseIPAddress": true,\n        "EnableGossipCompression": true,\n        "EnableExperimentalGossipEncryption": false,\n        "ReadOnlyConfig": true,\n        "GossipPort": 8074\n    },\n    "MetricsSettings": {\n        "Enable": false,\n        "BlockProfileRate": 0,\n        "ListenAddress": ":8067",\n        "EnableClientMetrics": true,\n        "EnableNotificationMetrics": true\n    },\n    "ExperimentalSettings": {\n        "ClientSideCertEnable": false,\n        "ClientSideCertCheck": "secondary",\n        "LinkMetadataTimeoutMilliseconds": 5000,\n        "RestrictSystemAdmin": false,\n        "EnableSharedChannels": false,\n        "EnableRemoteClusterService": false,\n        "DisableAppBar": false,\n        "DisableRefetchingOnBrowserFocus": false,\n        "DelayChannelAutocomplete": false,\n        "DisableWakeUpReconnectHandler": false,\n        "UsersStatusAndProfileFetchingPollIntervalMilliseconds": 3000,\n        "YoutubeReferrerPolicy": false\n    },\n    "AnalyticsSettings": {\n        "MaxUsersForStatistics": 2500\n    },\n    "ElasticsearchSettings": {\n        "ConnectionURL": "http://localhost:9200",\n        "Backend": "elasticsearch",\n        "Username": "elastic",\n        "Password": "changeme",\n        "EnableIndexing": false,\n        "EnableSearching": false,\n        "EnableAutocomplete": false,\n        "Sniff": true,\n        "PostIndexReplicas": 1,\n        "PostIndexShards": 1,\n        "ChannelIndexReplicas": 1,\n        "ChannelIndexShards": 1,\n        "UserIndexReplicas": 1,\n        "UserIndexShards": 1,\n        "AggregatePostsAfterDays": 365,\n        "PostsAggregatorJobStartTime": "03:00",\n        "IndexPrefix": "",\n        "LiveIndexingBatchSize": 10,\n        "BatchSize": 10000,\n        "RequestTimeoutSeconds": 30,\n        "SkipTLSVerification": false,\n        "CA": "",\n        "ClientCert": "",\n        "ClientKey": "",\n        "Trace": "",\n        "IgnoredPurgeIndexes": ""\n    },\n    "BleveSettings": {\n        "IndexDir": "",\n        "EnableIndexing": false,\n        "EnableSearching": false,\n        "EnableAutocomplete": false,\n        "BatchSize": 10000\n    },\n    "DataRetentionSettings": {\n        "EnableMessageDeletion": false,\n        "EnableFileDeletion": false,\n        "EnableBoardsDeletion": false,\n        "MessageRetentionDays": 365,\n        "MessageRetentionHours": 0,\n        "FileRetentionDays": 365,\n        "FileRetentionHours": 0,\n        "BoardsRetentionDays": 365,\n        "DeletionJobStartTime": "02:00",\n        "BatchSize": 3000,\n        "TimeBetweenBatchesMilliseconds": 100,\n        "RetentionIdsBatchSize": 100\n    },\n    "MessageExportSettings": {\n        "EnableExport": false,\n        "ExportFormat": "actiance",\n        "DailyRunTime": "01:00",\n        "ExportFromTimestamp": 0,\n        "BatchSize": 10000,\n        "DownloadExportResults": false,\n        "ChannelBatchSize": 100,\n        "ChannelHistoryBatchSize": 10,\n        "GlobalRelaySettings": {\n            "CustomerType": "A9",\n            "SMTPUsername": "",\n            "SMTPPassword": "",\n            "EmailAddress": "",\n            "SMTPServerTimeout": 1800,\n            "CustomSMTPServerName": "",\n            "CustomSMTPPort": "25"\n        }\n    },\n    "JobSettings": {\n        "RunJobs": true,\n        "RunScheduler": true,\n        "CleanupJobsThresholdDays": -1,\n        "CleanupConfigThresholdDays": -1\n    },\n    "PluginSettings": {\n        "Enable": true,\n        "EnableUploads": false,\n        "AllowInsecureDownloadURL": false,\n        "EnableHealthCheck": true,\n        "Directory": "./plugins",\n        "ClientDirectory": "./client/plugins",\n        "Plugins": {},\n        "PluginStates": {\n            "com.mattermost.calls": {\n                "Enable": true\n            },\n            "com.mattermost.nps": {\n                "Enable": true\n            },\n            "mattermost-ai": {\n                "Enable": true\n            },\n            "playbooks": {\n                "Enable": true\n            }\n        },\n        "EnableMarketplace": true,\n        "EnableRemoteMarketplace": true,\n        "AutomaticPrepackagedPlugins": true,\n        "RequirePluginSignature": false,\n        "MarketplaceURL": "https://api.integrations.mattermost.com",\n        "SignaturePublicKeyFiles": [],\n        "ChimeraOAuthProxyURL": ""\n    },\n    "DisplaySettings": {\n        "CustomURLSchemes": [],\n        "MaxMarkdownNodes": 0\n    },\n    "GuestAccountsSettings": {\n        "Enable": false,\n        "HideTags": false,\n        "AllowEmailAccounts": true,\n        "EnforceMultifactorAuthentication": false,\n        "RestrictCreationToDomains": ""\n    },\n    "ImageProxySettings": {\n        "Enable": false,\n        "ImageProxyType": "local",\n        "RemoteImageProxyURL": "",\n        "RemoteImageProxyOptions": ""\n    },\n    "CloudSettings": {\n        "CWSURL": "https://customers.mattermost.com",\n        "CWSAPIURL": "https://portal.internal.prod.cloud.mattermost.com",\n        "CWSMock": false,\n        "Disable": false\n    },\n    "ImportSettings": {\n        "Directory": "./import",\n        "RetentionDays": 30\n    },\n    "ExportSettings": {\n        "Directory": "./export",\n        "RetentionDays": 30\n    },\n    "WranglerSettings": {\n        "PermittedWranglerRoles": [],\n        "AllowedEmailDomain": [],\n        "MoveThreadMaxCount": 100,\n        "MoveThreadToAnotherTeamEnable": false,\n        "MoveThreadFromPrivateChannelEnable": false,\n        "MoveThreadFromDirectMessageChannelEnable": false,\n        "MoveThreadFromGroupMessageChannelEnable": false\n    },\n    "ConnectedWorkspacesSettings": {\n        "EnableSharedChannels": false,\n        "EnableRemoteClusterService": false,\n        "DisableSharedChannelsStatusSync": false,\n        "MaxPostsPerSync": 50\n    }\n}	1771646011580	\N	5da89ea797a1686ef6359eff14b15d487a4d85d1846580f541cd889771dc8f9c
ppiq3o99djntjgn9kdt6xey7ae	{\n    "ServiceSettings": {\n        "SiteURL": "",\n        "WebsocketURL": "",\n        "LicenseFileLocation": "",\n        "ListenAddress": ":8065",\n        "ConnectionSecurity": "",\n        "TLSCertFile": "",\n        "TLSKeyFile": "",\n        "TLSMinVer": "1.2",\n        "TLSStrictTransport": false,\n        "TLSStrictTransportMaxAge": 63072000,\n        "TLSOverwriteCiphers": [],\n        "UseLetsEncrypt": false,\n        "LetsEncryptCertificateCacheFile": "./config/letsencrypt.cache",\n        "Forward80To443": false,\n        "TrustedProxyIPHeader": [],\n        "ReadTimeout": 300,\n        "WriteTimeout": 300,\n        "IdleTimeout": 60,\n        "MaximumLoginAttempts": 10,\n        "GoroutineHealthThreshold": -1,\n        "EnableOAuthServiceProvider": true,\n        "EnableIncomingWebhooks": true,\n        "EnableOutgoingWebhooks": true,\n        "EnableOutgoingOAuthConnections": false,\n        "EnableCommands": true,\n        "OutgoingIntegrationRequestsTimeout": 30,\n        "EnablePostUsernameOverride": false,\n        "EnablePostIconOverride": false,\n        "GoogleDeveloperKey": "",\n        "EnableLinkPreviews": true,\n        "EnablePermalinkPreviews": true,\n        "RestrictLinkPreviews": "",\n        "EnableTesting": false,\n        "EnableDeveloper": false,\n        "DeveloperFlags": "",\n        "EnableClientPerformanceDebugging": false,\n        "EnableOpenTracing": false,\n        "EnableSecurityFixAlert": true,\n        "EnableInsecureOutgoingConnections": false,\n        "AllowedUntrustedInternalConnections": "",\n        "EnableMultifactorAuthentication": false,\n        "EnforceMultifactorAuthentication": false,\n        "EnableUserAccessTokens": false,\n        "AllowCorsFrom": "",\n        "CorsExposedHeaders": "",\n        "CorsAllowCredentials": false,\n        "CorsDebug": false,\n        "AllowCookiesForSubdomains": false,\n        "ExtendSessionLengthWithActivity": false,\n        "TerminateSessionsOnPasswordChange": false,\n        "SessionLengthWebInDays": 180,\n        "SessionLengthWebInHours": 4320,\n        "SessionLengthMobileInDays": 180,\n        "SessionLengthMobileInHours": 4320,\n        "SessionLengthSSOInDays": 30,\n        "SessionLengthSSOInHours": 720,\n        "SessionCacheInMinutes": 10,\n        "SessionIdleTimeoutInMinutes": 43200,\n        "WebsocketSecurePort": 443,\n        "WebsocketPort": 80,\n        "WebserverMode": "gzip",\n        "EnableGifPicker": true,\n        "GiphySdkKey": "",\n        "EnableCustomEmoji": true,\n        "EnableEmojiPicker": true,\n        "PostEditTimeLimit": -1,\n        "TimeBetweenUserTypingUpdatesMilliseconds": 5000,\n        "EnablePostSearch": true,\n        "EnableFileSearch": true,\n        "MinimumHashtagLength": 3,\n        "EnableUserTypingMessages": true,\n        "EnableChannelViewedMessages": true,\n        "EnableUserStatuses": true,\n        "ExperimentalEnableAuthenticationTransfer": true,\n        "ClusterLogTimeoutMilliseconds": 2000,\n        "EnableTutorial": true,\n        "EnableOnboardingFlow": true,\n        "ExperimentalEnableDefaultChannelLeaveJoinMessages": true,\n        "ExperimentalGroupUnreadChannels": "disabled",\n        "EnableAPITeamDeletion": false,\n        "EnableAPITriggerAdminNotifications": false,\n        "EnableAPIUserDeletion": false,\n        "EnableAPIPostDeletion": false,\n        "EnableDesktopLandingPage": true,\n        "ExperimentalEnableHardenedMode": false,\n        "ExperimentalStrictCSRFEnforcement": false,\n        "EnableEmailInvitations": true,\n        "DisableBotsWhenOwnerIsDeactivated": true,\n        "EnableBotAccountCreation": false,\n        "EnableSVGs": true,\n        "EnableLatex": true,\n        "EnableInlineLatex": true,\n        "PostPriority": true,\n        "AllowPersistentNotifications": true,\n        "AllowPersistentNotificationsForGuests": false,\n        "PersistentNotificationIntervalMinutes": 5,\n        "PersistentNotificationMaxCount": 6,\n        "PersistentNotificationMaxRecipients": 5,\n        "EnableAPIChannelDeletion": false,\n        "EnableLocalMode": false,\n        "LocalModeSocketLocation": "/var/tmp/mattermost_local.socket",\n        "EnableAWSMetering": false,\n        "SplitKey": "",\n        "FeatureFlagSyncIntervalSeconds": 30,\n        "DebugSplit": false,\n        "ThreadAutoFollow": true,\n        "CollapsedThreads": "always_on",\n        "ManagedResourcePaths": "",\n        "EnableCustomGroups": true,\n        "AllowSyncedDrafts": true,\n        "UniqueEmojiReactionLimitPerPost": 50,\n        "RefreshPostStatsRunTime": "00:00",\n        "MaximumPayloadSizeBytes": 300000,\n        "MaximumURLLength": 2048,\n        "ScheduledPosts": true,\n        "EnableWebHubChannelIteration": false\n    },\n    "TeamSettings": {\n        "SiteName": "Mattermost",\n        "MaxUsersPerTeam": 50,\n        "EnableJoinLeaveMessageByDefault": true,\n        "EnableUserCreation": true,\n        "EnableOpenServer": false,\n        "EnableUserDeactivation": false,\n        "RestrictCreationToDomains": "",\n        "EnableCustomUserStatuses": true,\n        "EnableCustomBrand": false,\n        "CustomBrandText": "",\n        "CustomDescriptionText": "",\n        "RestrictDirectMessage": "any",\n        "EnableLastActiveTime": true,\n        "UserStatusAwayTimeout": 300,\n        "MaxChannelsPerTeam": 2000,\n        "MaxNotificationsPerChannel": 1000,\n        "EnableConfirmNotificationsToChannel": true,\n        "TeammateNameDisplay": "username",\n        "ExperimentalViewArchivedChannels": true,\n        "ExperimentalEnableAutomaticReplies": false,\n        "LockTeammateNameDisplay": false,\n        "ExperimentalPrimaryTeam": "",\n        "ExperimentalDefaultChannels": []\n    },\n    "ClientRequirements": {\n        "AndroidLatestVersion": "",\n        "AndroidMinVersion": "",\n        "IosLatestVersion": "",\n        "IosMinVersion": ""\n    },\n    "SqlSettings": {\n        "DriverName": "postgres",\n        "DataSource": "postgres://mattermost_user:mattermost_pw@postgres.zoo/mattermost_db?sslmode=disable",\n        "DataSourceReplicas": [],\n        "DataSourceSearchReplicas": [],\n        "MaxIdleConns": 20,\n        "ConnMaxLifetimeMilliseconds": 3600000,\n        "ConnMaxIdleTimeMilliseconds": 300000,\n        "MaxOpenConns": 300,\n        "Trace": false,\n        "AtRestEncryptKey": "51z7tarrgmz9wzcnt8rumnzkqsdukrxr",\n        "QueryTimeout": 30,\n        "DisableDatabaseSearch": false,\n        "MigrationsStatementTimeoutSeconds": 100000,\n        "ReplicaLagSettings": [],\n        "ReplicaMonitorIntervalSeconds": 5\n    },\n    "LogSettings": {\n        "EnableConsole": true,\n        "ConsoleLevel": "DEBUG",\n        "ConsoleJson": true,\n        "EnableColor": false,\n        "EnableFile": true,\n        "FileLevel": "INFO",\n        "FileJson": true,\n        "FileLocation": "",\n        "EnableWebhookDebugging": true,\n        "EnableDiagnostics": true,\n        "VerboseDiagnostics": false,\n        "EnableSentry": true,\n        "AdvancedLoggingJSON": null,\n        "MaxFieldSize": 2048\n    },\n    "ExperimentalAuditSettings": {\n        "FileEnabled": false,\n        "FileName": "",\n        "FileMaxSizeMB": 100,\n        "FileMaxAgeDays": 0,\n        "FileMaxBackups": 0,\n        "FileCompress": false,\n        "FileMaxQueueSize": 1000,\n        "AdvancedLoggingJSON": null\n    },\n    "NotificationLogSettings": {\n        "EnableConsole": true,\n        "ConsoleLevel": "DEBUG",\n        "ConsoleJson": true,\n        "EnableColor": false,\n        "EnableFile": true,\n        "FileLevel": "INFO",\n        "FileJson": true,\n        "FileLocation": "",\n        "AdvancedLoggingJSON": null\n    },\n    "PasswordSettings": {\n        "MinimumLength": 8,\n        "Lowercase": false,\n        "Number": false,\n        "Uppercase": false,\n        "Symbol": false,\n        "EnableForgotLink": true\n    },\n    "FileSettings": {\n        "EnableFileAttachments": true,\n        "EnableMobileUpload": true,\n        "EnableMobileDownload": true,\n        "MaxFileSize": 104857600,\n        "MaxImageResolution": 33177600,\n        "MaxImageDecoderConcurrency": -1,\n        "DriverName": "local",\n        "Directory": "./data/",\n        "EnablePublicLink": false,\n        "ExtractContent": true,\n        "ArchiveRecursion": false,\n        "PublicLinkSalt": "qteo68ysr89by8wjnarggb53tguak4eo",\n        "InitialFont": "nunito-bold.ttf",\n        "AmazonS3AccessKeyId": "",\n        "AmazonS3SecretAccessKey": "",\n        "AmazonS3Bucket": "",\n        "AmazonS3PathPrefix": "",\n        "AmazonS3Region": "",\n        "AmazonS3Endpoint": "s3.amazonaws.com",\n        "AmazonS3SSL": true,\n        "AmazonS3SignV2": false,\n        "AmazonS3SSE": false,\n        "AmazonS3Trace": false,\n        "AmazonS3RequestTimeoutMilliseconds": 30000,\n        "AmazonS3UploadPartSizeBytes": 5242880,\n        "AmazonS3StorageClass": "",\n        "DedicatedExportStore": false,\n        "ExportDriverName": "local",\n        "ExportDirectory": "./data/",\n        "ExportAmazonS3AccessKeyId": "",\n        "ExportAmazonS3SecretAccessKey": "",\n        "ExportAmazonS3Bucket": "",\n        "ExportAmazonS3PathPrefix": "",\n        "ExportAmazonS3Region": "",\n        "ExportAmazonS3Endpoint": "s3.amazonaws.com",\n        "ExportAmazonS3SSL": true,\n        "ExportAmazonS3SignV2": false,\n        "ExportAmazonS3SSE": false,\n        "ExportAmazonS3Trace": false,\n        "ExportAmazonS3RequestTimeoutMilliseconds": 30000,\n        "ExportAmazonS3PresignExpiresSeconds": 21600,\n        "ExportAmazonS3UploadPartSizeBytes": 104857600,\n        "ExportAmazonS3StorageClass": ""\n    },\n    "EmailSettings": {\n        "EnableSignUpWithEmail": true,\n        "EnableSignInWithEmail": true,\n        "EnableSignInWithUsername": true,\n        "SendEmailNotifications": true,\n        "UseChannelInEmailNotifications": false,\n        "RequireEmailVerification": false,\n        "FeedbackName": "",\n        "FeedbackEmail": "test@example.com",\n        "ReplyToAddress": "test@example.com",\n        "FeedbackOrganization": "",\n        "EnableSMTPAuth": false,\n        "SMTPUsername": "",\n        "SMTPPassword": "",\n        "SMTPServer": "localhost",\n        "SMTPPort": "10025",\n        "SMTPServerTimeout": 10,\n        "ConnectionSecurity": "",\n        "SendPushNotifications": false,\n        "PushNotificationServer": "",\n        "PushNotificationContents": "full",\n        "PushNotificationBuffer": 1000,\n        "EnableEmailBatching": false,\n        "EmailBatchingBufferSize": 256,\n        "EmailBatchingInterval": 30,\n        "EnablePreviewModeBanner": true,\n        "SkipServerCertificateVerification": false,\n        "EmailNotificationContentsType": "full",\n        "LoginButtonColor": "#0000",\n        "LoginButtonBorderColor": "#2389D7",\n        "LoginButtonTextColor": "#2389D7"\n    },\n    "RateLimitSettings": {\n        "Enable": false,\n        "PerSec": 10,\n        "MaxBurst": 100,\n        "MemoryStoreSize": 10000,\n        "VaryByRemoteAddr": true,\n        "VaryByUser": false,\n        "VaryByHeader": ""\n    },\n    "PrivacySettings": {\n        "ShowEmailAddress": true,\n        "ShowFullName": true\n    },\n    "SupportSettings": {\n        "TermsOfServiceLink": "https://mattermost.com/pl/terms-of-use/",\n        "PrivacyPolicyLink": "https://mattermost.com/pl/privacy-policy/",\n        "AboutLink": "https://mattermost.com/pl/about-mattermost",\n        "HelpLink": "https://mattermost.com/pl/help/",\n        "ReportAProblemLink": "https://mattermost.com/pl/report-a-bug",\n        "ForgotPasswordLink": "",\n        "SupportEmail": "",\n        "CustomTermsOfServiceEnabled": false,\n        "CustomTermsOfServiceReAcceptancePeriod": 365,\n        "EnableAskCommunityLink": true\n    },\n    "AnnouncementSettings": {\n        "EnableBanner": false,\n        "BannerText": "",\n        "BannerColor": "#f2a93b",\n        "BannerTextColor": "#333333",\n        "AllowBannerDismissal": true,\n        "AdminNoticesEnabled": true,\n        "UserNoticesEnabled": true,\n        "NoticesURL": "https://notices.mattermost.com/",\n        "NoticesFetchFrequency": 3600,\n        "NoticesSkipCache": false\n    },\n    "ThemeSettings": {\n        "EnableThemeSelection": true,\n        "DefaultTheme": "default",\n        "AllowCustomThemes": true,\n        "AllowedThemes": []\n    },\n    "GitLabSettings": {\n        "Enable": false,\n        "Secret": "",\n        "Id": "",\n        "Scope": "",\n        "AuthEndpoint": "",\n        "TokenEndpoint": "",\n        "UserAPIEndpoint": "",\n        "DiscoveryEndpoint": "",\n        "ButtonText": "",\n        "ButtonColor": ""\n    },\n    "GoogleSettings": {\n        "Enable": false,\n        "Secret": "",\n        "Id": "",\n        "Scope": "profile email",\n        "AuthEndpoint": "https://accounts.google.com/o/oauth2/v2/auth",\n        "TokenEndpoint": "https://www.googleapis.com/oauth2/v4/token",\n        "UserAPIEndpoint": "https://people.googleapis.com/v1/people/me?personFields=names,emailAddresses,nicknames,metadata",\n        "DiscoveryEndpoint": "",\n        "ButtonText": "",\n        "ButtonColor": ""\n    },\n    "Office365Settings": {\n        "Enable": false,\n        "Secret": "",\n        "Id": "",\n        "Scope": "User.Read",\n        "AuthEndpoint": "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",\n        "TokenEndpoint": "https://login.microsoftonline.com/common/oauth2/v2.0/token",\n        "UserAPIEndpoint": "https://graph.microsoft.com/v1.0/me",\n        "DiscoveryEndpoint": "",\n        "DirectoryId": ""\n    },\n    "OpenIdSettings": {\n        "Enable": false,\n        "Secret": "",\n        "Id": "",\n        "Scope": "profile openid email",\n        "AuthEndpoint": "",\n        "TokenEndpoint": "",\n        "UserAPIEndpoint": "",\n        "DiscoveryEndpoint": "",\n        "ButtonText": "",\n        "ButtonColor": "#145DBF"\n    },\n    "LdapSettings": {\n        "Enable": false,\n        "EnableSync": false,\n        "LdapServer": "",\n        "LdapPort": 389,\n        "ConnectionSecurity": "",\n        "BaseDN": "",\n        "BindUsername": "",\n        "BindPassword": "",\n        "MaximumLoginAttempts": 10,\n        "UserFilter": "",\n        "GroupFilter": "",\n        "GuestFilter": "",\n        "EnableAdminFilter": false,\n        "AdminFilter": "",\n        "GroupDisplayNameAttribute": "",\n        "GroupIdAttribute": "",\n        "FirstNameAttribute": "",\n        "LastNameAttribute": "",\n        "EmailAttribute": "",\n        "UsernameAttribute": "",\n        "NicknameAttribute": "",\n        "IdAttribute": "",\n        "PositionAttribute": "",\n        "LoginIdAttribute": "",\n        "PictureAttribute": "",\n        "SyncIntervalMinutes": 60,\n        "SkipCertificateVerification": false,\n        "PublicCertificateFile": "",\n        "PrivateKeyFile": "",\n        "QueryTimeout": 60,\n        "MaxPageSize": 0,\n        "LoginFieldName": "",\n        "LoginButtonColor": "#0000",\n        "LoginButtonBorderColor": "#2389D7",\n        "LoginButtonTextColor": "#2389D7"\n    },\n    "ComplianceSettings": {\n        "Enable": false,\n        "Directory": "./data/",\n        "EnableDaily": false,\n        "BatchSize": 30000\n    },\n    "LocalizationSettings": {\n        "DefaultServerLocale": "en",\n        "DefaultClientLocale": "en",\n        "AvailableLocales": "",\n        "EnableExperimentalLocales": false\n    },\n    "SamlSettings": {\n        "Enable": false,\n        "EnableSyncWithLdap": false,\n        "EnableSyncWithLdapIncludeAuth": false,\n        "IgnoreGuestsLdapSync": false,\n        "Verify": true,\n        "Encrypt": true,\n        "SignRequest": false,\n        "IdpURL": "",\n        "IdpDescriptorURL": "",\n        "IdpMetadataURL": "",\n        "ServiceProviderIdentifier": "",\n        "AssertionConsumerServiceURL": "",\n        "SignatureAlgorithm": "RSAwithSHA1",\n        "CanonicalAlgorithm": "Canonical1.0",\n        "ScopingIDPProviderId": "",\n        "ScopingIDPName": "",\n        "IdpCertificateFile": "",\n        "PublicCertificateFile": "",\n        "PrivateKeyFile": "",\n        "IdAttribute": "",\n        "GuestAttribute": "",\n        "EnableAdminAttribute": false,\n        "AdminAttribute": "",\n        "FirstNameAttribute": "",\n        "LastNameAttribute": "",\n        "EmailAttribute": "",\n        "UsernameAttribute": "",\n        "NicknameAttribute": "",\n        "LocaleAttribute": "",\n        "PositionAttribute": "",\n        "LoginButtonText": "SAML",\n        "LoginButtonColor": "#34a28b",\n        "LoginButtonBorderColor": "#2389D7",\n        "LoginButtonTextColor": "#ffffff"\n    },\n    "NativeAppSettings": {\n        "AppCustomURLSchemes": [\n            "mmauth://",\n            "mmauthbeta://"\n        ],\n        "AppDownloadLink": "https://mattermost.com/pl/download-apps",\n        "AndroidAppDownloadLink": "https://mattermost.com/pl/android-app/",\n        "IosAppDownloadLink": "https://mattermost.com/pl/ios-app/",\n        "MobileExternalBrowser": false\n    },\n    "CacheSettings": {\n        "CacheType": "lru",\n        "RedisAddress": "",\n        "RedisPassword": "********************************",\n        "RedisDB": -1,\n        "DisableClientCache": false\n    },\n    "ClusterSettings": {\n        "Enable": false,\n        "ClusterName": "",\n        "OverrideHostname": "",\n        "NetworkInterface": "",\n        "BindAddress": "",\n        "AdvertiseAddress": "",\n        "UseIPAddress": true,\n        "EnableGossipCompression": true,\n        "EnableExperimentalGossipEncryption": false,\n        "ReadOnlyConfig": true,\n        "GossipPort": 8074\n    },\n    "MetricsSettings": {\n        "Enable": false,\n        "BlockProfileRate": 0,\n        "ListenAddress": ":8067",\n        "EnableClientMetrics": true,\n        "EnableNotificationMetrics": true\n    },\n    "ExperimentalSettings": {\n        "ClientSideCertEnable": false,\n        "ClientSideCertCheck": "secondary",\n        "LinkMetadataTimeoutMilliseconds": 5000,\n        "RestrictSystemAdmin": false,\n        "EnableSharedChannels": false,\n        "EnableRemoteClusterService": false,\n        "DisableAppBar": false,\n        "DisableRefetchingOnBrowserFocus": false,\n        "DelayChannelAutocomplete": false,\n        "DisableWakeUpReconnectHandler": false,\n        "UsersStatusAndProfileFetchingPollIntervalMilliseconds": 3000,\n        "YoutubeReferrerPolicy": false\n    },\n    "AnalyticsSettings": {\n        "MaxUsersForStatistics": 2500\n    },\n    "ElasticsearchSettings": {\n        "ConnectionURL": "http://localhost:9200",\n        "Backend": "elasticsearch",\n        "Username": "elastic",\n        "Password": "changeme",\n        "EnableIndexing": false,\n        "EnableSearching": false,\n        "EnableAutocomplete": false,\n        "Sniff": true,\n        "PostIndexReplicas": 1,\n        "PostIndexShards": 1,\n        "ChannelIndexReplicas": 1,\n        "ChannelIndexShards": 1,\n        "UserIndexReplicas": 1,\n        "UserIndexShards": 1,\n        "AggregatePostsAfterDays": 365,\n        "PostsAggregatorJobStartTime": "03:00",\n        "IndexPrefix": "",\n        "LiveIndexingBatchSize": 10,\n        "BatchSize": 10000,\n        "RequestTimeoutSeconds": 30,\n        "SkipTLSVerification": false,\n        "CA": "",\n        "ClientCert": "",\n        "ClientKey": "",\n        "Trace": "",\n        "IgnoredPurgeIndexes": ""\n    },\n    "BleveSettings": {\n        "IndexDir": "",\n        "EnableIndexing": false,\n        "EnableSearching": false,\n        "EnableAutocomplete": false,\n        "BatchSize": 10000\n    },\n    "DataRetentionSettings": {\n        "EnableMessageDeletion": false,\n        "EnableFileDeletion": false,\n        "EnableBoardsDeletion": false,\n        "MessageRetentionDays": 365,\n        "MessageRetentionHours": 0,\n        "FileRetentionDays": 365,\n        "FileRetentionHours": 0,\n        "BoardsRetentionDays": 365,\n        "DeletionJobStartTime": "02:00",\n        "BatchSize": 3000,\n        "TimeBetweenBatchesMilliseconds": 100,\n        "RetentionIdsBatchSize": 100\n    },\n    "MessageExportSettings": {\n        "EnableExport": false,\n        "ExportFormat": "actiance",\n        "DailyRunTime": "01:00",\n        "ExportFromTimestamp": 0,\n        "BatchSize": 10000,\n        "DownloadExportResults": false,\n        "ChannelBatchSize": 100,\n        "ChannelHistoryBatchSize": 10,\n        "GlobalRelaySettings": {\n            "CustomerType": "A9",\n            "SMTPUsername": "",\n            "SMTPPassword": "",\n            "EmailAddress": "",\n            "SMTPServerTimeout": 1800,\n            "CustomSMTPServerName": "",\n            "CustomSMTPPort": "25"\n        }\n    },\n    "JobSettings": {\n        "RunJobs": true,\n        "RunScheduler": true,\n        "CleanupJobsThresholdDays": -1,\n        "CleanupConfigThresholdDays": -1\n    },\n    "PluginSettings": {\n        "Enable": true,\n        "EnableUploads": false,\n        "AllowInsecureDownloadURL": false,\n        "EnableHealthCheck": true,\n        "Directory": "./plugins",\n        "ClientDirectory": "./client/plugins",\n        "Plugins": {\n            "playbooks": {\n                "BotUserID": "oi9jhtfswpbtbfotpsuuj71zuc"\n            }\n        },\n        "PluginStates": {\n            "com.mattermost.calls": {\n                "Enable": true\n            },\n            "com.mattermost.nps": {\n                "Enable": true\n            },\n            "mattermost-ai": {\n                "Enable": true\n            },\n            "playbooks": {\n                "Enable": true\n            }\n        },\n        "EnableMarketplace": true,\n        "EnableRemoteMarketplace": true,\n        "AutomaticPrepackagedPlugins": true,\n        "RequirePluginSignature": false,\n        "MarketplaceURL": "https://api.integrations.mattermost.com",\n        "SignaturePublicKeyFiles": [],\n        "ChimeraOAuthProxyURL": ""\n    },\n    "DisplaySettings": {\n        "CustomURLSchemes": [],\n        "MaxMarkdownNodes": 0\n    },\n    "GuestAccountsSettings": {\n        "Enable": false,\n        "HideTags": false,\n        "AllowEmailAccounts": true,\n        "EnforceMultifactorAuthentication": false,\n        "RestrictCreationToDomains": ""\n    },\n    "ImageProxySettings": {\n        "Enable": false,\n        "ImageProxyType": "local",\n        "RemoteImageProxyURL": "",\n        "RemoteImageProxyOptions": ""\n    },\n    "CloudSettings": {\n        "CWSURL": "https://customers.mattermost.com",\n        "CWSAPIURL": "https://portal.internal.prod.cloud.mattermost.com",\n        "CWSMock": false,\n        "Disable": false\n    },\n    "ImportSettings": {\n        "Directory": "./import",\n        "RetentionDays": 30\n    },\n    "ExportSettings": {\n        "Directory": "./export",\n        "RetentionDays": 30\n    },\n    "WranglerSettings": {\n        "PermittedWranglerRoles": [],\n        "AllowedEmailDomain": [],\n        "MoveThreadMaxCount": 100,\n        "MoveThreadToAnotherTeamEnable": false,\n        "MoveThreadFromPrivateChannelEnable": false,\n        "MoveThreadFromDirectMessageChannelEnable": false,\n        "MoveThreadFromGroupMessageChannelEnable": false\n    },\n    "ConnectedWorkspacesSettings": {\n        "EnableSharedChannels": false,\n        "EnableRemoteClusterService": false,\n        "DisableSharedChannelsStatusSync": false,\n        "MaxPostsPerSync": 50\n    }\n}	1771646012445	\N	4c74ec1eedae983be23e703cd78d35f50d746cd1c60ed3527f64998f6fd9a799
1btq6erwoif6ig71mpgrjm8qxc	{\n    "ServiceSettings": {\n        "SiteURL": "",\n        "WebsocketURL": "",\n        "LicenseFileLocation": "",\n        "ListenAddress": ":8065",\n        "ConnectionSecurity": "",\n        "TLSCertFile": "",\n        "TLSKeyFile": "",\n        "TLSMinVer": "1.2",\n        "TLSStrictTransport": false,\n        "TLSStrictTransportMaxAge": 63072000,\n        "TLSOverwriteCiphers": [],\n        "UseLetsEncrypt": false,\n        "LetsEncryptCertificateCacheFile": "./config/letsencrypt.cache",\n        "Forward80To443": false,\n        "TrustedProxyIPHeader": [],\n        "ReadTimeout": 300,\n        "WriteTimeout": 300,\n        "IdleTimeout": 60,\n        "MaximumLoginAttempts": 10,\n        "GoroutineHealthThreshold": -1,\n        "EnableOAuthServiceProvider": true,\n        "EnableIncomingWebhooks": true,\n        "EnableOutgoingWebhooks": true,\n        "EnableOutgoingOAuthConnections": false,\n        "EnableCommands": true,\n        "OutgoingIntegrationRequestsTimeout": 30,\n        "EnablePostUsernameOverride": false,\n        "EnablePostIconOverride": false,\n        "GoogleDeveloperKey": "",\n        "EnableLinkPreviews": true,\n        "EnablePermalinkPreviews": true,\n        "RestrictLinkPreviews": "",\n        "EnableTesting": false,\n        "EnableDeveloper": false,\n        "DeveloperFlags": "",\n        "EnableClientPerformanceDebugging": false,\n        "EnableOpenTracing": false,\n        "EnableSecurityFixAlert": true,\n        "EnableInsecureOutgoingConnections": false,\n        "AllowedUntrustedInternalConnections": "",\n        "EnableMultifactorAuthentication": false,\n        "EnforceMultifactorAuthentication": false,\n        "EnableUserAccessTokens": false,\n        "AllowCorsFrom": "",\n        "CorsExposedHeaders": "",\n        "CorsAllowCredentials": false,\n        "CorsDebug": false,\n        "AllowCookiesForSubdomains": false,\n        "ExtendSessionLengthWithActivity": false,\n        "TerminateSessionsOnPasswordChange": false,\n        "SessionLengthWebInDays": 180,\n        "SessionLengthWebInHours": 4320,\n        "SessionLengthMobileInDays": 180,\n        "SessionLengthMobileInHours": 4320,\n        "SessionLengthSSOInDays": 30,\n        "SessionLengthSSOInHours": 720,\n        "SessionCacheInMinutes": 10,\n        "SessionIdleTimeoutInMinutes": 43200,\n        "WebsocketSecurePort": 443,\n        "WebsocketPort": 80,\n        "WebserverMode": "gzip",\n        "EnableGifPicker": true,\n        "GiphySdkKey": "",\n        "EnableCustomEmoji": true,\n        "EnableEmojiPicker": true,\n        "PostEditTimeLimit": -1,\n        "TimeBetweenUserTypingUpdatesMilliseconds": 5000,\n        "EnablePostSearch": true,\n        "EnableFileSearch": true,\n        "MinimumHashtagLength": 3,\n        "EnableUserTypingMessages": true,\n        "EnableChannelViewedMessages": true,\n        "EnableUserStatuses": true,\n        "ExperimentalEnableAuthenticationTransfer": true,\n        "ClusterLogTimeoutMilliseconds": 2000,\n        "EnableTutorial": true,\n        "EnableOnboardingFlow": true,\n        "ExperimentalEnableDefaultChannelLeaveJoinMessages": true,\n        "ExperimentalGroupUnreadChannels": "disabled",\n        "EnableAPITeamDeletion": false,\n        "EnableAPITriggerAdminNotifications": false,\n        "EnableAPIUserDeletion": false,\n        "EnableAPIPostDeletion": false,\n        "EnableDesktopLandingPage": true,\n        "ExperimentalEnableHardenedMode": false,\n        "ExperimentalStrictCSRFEnforcement": false,\n        "EnableEmailInvitations": true,\n        "DisableBotsWhenOwnerIsDeactivated": true,\n        "EnableBotAccountCreation": false,\n        "EnableSVGs": true,\n        "EnableLatex": true,\n        "EnableInlineLatex": true,\n        "PostPriority": true,\n        "AllowPersistentNotifications": true,\n        "AllowPersistentNotificationsForGuests": false,\n        "PersistentNotificationIntervalMinutes": 5,\n        "PersistentNotificationMaxCount": 6,\n        "PersistentNotificationMaxRecipients": 5,\n        "EnableAPIChannelDeletion": false,\n        "EnableLocalMode": false,\n        "LocalModeSocketLocation": "/var/tmp/mattermost_local.socket",\n        "EnableAWSMetering": false,\n        "SplitKey": "",\n        "FeatureFlagSyncIntervalSeconds": 30,\n        "DebugSplit": false,\n        "ThreadAutoFollow": true,\n        "CollapsedThreads": "always_on",\n        "ManagedResourcePaths": "",\n        "EnableCustomGroups": true,\n        "AllowSyncedDrafts": true,\n        "UniqueEmojiReactionLimitPerPost": 50,\n        "RefreshPostStatsRunTime": "00:00",\n        "MaximumPayloadSizeBytes": 300000,\n        "MaximumURLLength": 2048,\n        "ScheduledPosts": true,\n        "EnableWebHubChannelIteration": false\n    },\n    "TeamSettings": {\n        "SiteName": "Mattermost",\n        "MaxUsersPerTeam": 50,\n        "EnableJoinLeaveMessageByDefault": true,\n        "EnableUserCreation": true,\n        "EnableOpenServer": false,\n        "EnableUserDeactivation": false,\n        "RestrictCreationToDomains": "",\n        "EnableCustomUserStatuses": true,\n        "EnableCustomBrand": false,\n        "CustomBrandText": "",\n        "CustomDescriptionText": "",\n        "RestrictDirectMessage": "any",\n        "EnableLastActiveTime": true,\n        "UserStatusAwayTimeout": 300,\n        "MaxChannelsPerTeam": 2000,\n        "MaxNotificationsPerChannel": 1000,\n        "EnableConfirmNotificationsToChannel": true,\n        "TeammateNameDisplay": "username",\n        "ExperimentalViewArchivedChannels": true,\n        "ExperimentalEnableAutomaticReplies": false,\n        "LockTeammateNameDisplay": false,\n        "ExperimentalPrimaryTeam": "",\n        "ExperimentalDefaultChannels": []\n    },\n    "ClientRequirements": {\n        "AndroidLatestVersion": "",\n        "AndroidMinVersion": "",\n        "IosLatestVersion": "",\n        "IosMinVersion": ""\n    },\n    "SqlSettings": {\n        "DriverName": "postgres",\n        "DataSource": "postgres://mattermost_user:mattermost_pw@postgres.zoo/mattermost_db?sslmode=disable",\n        "DataSourceReplicas": [],\n        "DataSourceSearchReplicas": [],\n        "MaxIdleConns": 20,\n        "ConnMaxLifetimeMilliseconds": 3600000,\n        "ConnMaxIdleTimeMilliseconds": 300000,\n        "MaxOpenConns": 300,\n        "Trace": false,\n        "AtRestEncryptKey": "51z7tarrgmz9wzcnt8rumnzkqsdukrxr",\n        "QueryTimeout": 30,\n        "DisableDatabaseSearch": false,\n        "MigrationsStatementTimeoutSeconds": 100000,\n        "ReplicaLagSettings": [],\n        "ReplicaMonitorIntervalSeconds": 5\n    },\n    "LogSettings": {\n        "EnableConsole": true,\n        "ConsoleLevel": "DEBUG",\n        "ConsoleJson": true,\n        "EnableColor": false,\n        "EnableFile": true,\n        "FileLevel": "INFO",\n        "FileJson": true,\n        "FileLocation": "",\n        "EnableWebhookDebugging": true,\n        "EnableDiagnostics": true,\n        "VerboseDiagnostics": false,\n        "EnableSentry": true,\n        "AdvancedLoggingJSON": null,\n        "MaxFieldSize": 2048\n    },\n    "ExperimentalAuditSettings": {\n        "FileEnabled": false,\n        "FileName": "",\n        "FileMaxSizeMB": 100,\n        "FileMaxAgeDays": 0,\n        "FileMaxBackups": 0,\n        "FileCompress": false,\n        "FileMaxQueueSize": 1000,\n        "AdvancedLoggingJSON": null\n    },\n    "NotificationLogSettings": {\n        "EnableConsole": true,\n        "ConsoleLevel": "DEBUG",\n        "ConsoleJson": true,\n        "EnableColor": false,\n        "EnableFile": true,\n        "FileLevel": "INFO",\n        "FileJson": true,\n        "FileLocation": "",\n        "AdvancedLoggingJSON": null\n    },\n    "PasswordSettings": {\n        "MinimumLength": 8,\n        "Lowercase": false,\n        "Number": false,\n        "Uppercase": false,\n        "Symbol": false,\n        "EnableForgotLink": true\n    },\n    "FileSettings": {\n        "EnableFileAttachments": true,\n        "EnableMobileUpload": true,\n        "EnableMobileDownload": true,\n        "MaxFileSize": 104857600,\n        "MaxImageResolution": 33177600,\n        "MaxImageDecoderConcurrency": -1,\n        "DriverName": "local",\n        "Directory": "./data/",\n        "EnablePublicLink": false,\n        "ExtractContent": true,\n        "ArchiveRecursion": false,\n        "PublicLinkSalt": "qteo68ysr89by8wjnarggb53tguak4eo",\n        "InitialFont": "nunito-bold.ttf",\n        "AmazonS3AccessKeyId": "",\n        "AmazonS3SecretAccessKey": "",\n        "AmazonS3Bucket": "",\n        "AmazonS3PathPrefix": "",\n        "AmazonS3Region": "",\n        "AmazonS3Endpoint": "s3.amazonaws.com",\n        "AmazonS3SSL": true,\n        "AmazonS3SignV2": false,\n        "AmazonS3SSE": false,\n        "AmazonS3Trace": false,\n        "AmazonS3RequestTimeoutMilliseconds": 30000,\n        "AmazonS3UploadPartSizeBytes": 5242880,\n        "AmazonS3StorageClass": "",\n        "DedicatedExportStore": false,\n        "ExportDriverName": "local",\n        "ExportDirectory": "./data/",\n        "ExportAmazonS3AccessKeyId": "",\n        "ExportAmazonS3SecretAccessKey": "",\n        "ExportAmazonS3Bucket": "",\n        "ExportAmazonS3PathPrefix": "",\n        "ExportAmazonS3Region": "",\n        "ExportAmazonS3Endpoint": "s3.amazonaws.com",\n        "ExportAmazonS3SSL": true,\n        "ExportAmazonS3SignV2": false,\n        "ExportAmazonS3SSE": false,\n        "ExportAmazonS3Trace": false,\n        "ExportAmazonS3RequestTimeoutMilliseconds": 30000,\n        "ExportAmazonS3PresignExpiresSeconds": 21600,\n        "ExportAmazonS3UploadPartSizeBytes": 104857600,\n        "ExportAmazonS3StorageClass": ""\n    },\n    "EmailSettings": {\n        "EnableSignUpWithEmail": true,\n        "EnableSignInWithEmail": true,\n        "EnableSignInWithUsername": true,\n        "SendEmailNotifications": true,\n        "UseChannelInEmailNotifications": false,\n        "RequireEmailVerification": false,\n        "FeedbackName": "",\n        "FeedbackEmail": "test@example.com",\n        "ReplyToAddress": "test@example.com",\n        "FeedbackOrganization": "",\n        "EnableSMTPAuth": false,\n        "SMTPUsername": "",\n        "SMTPPassword": "",\n        "SMTPServer": "localhost",\n        "SMTPPort": "10025",\n        "SMTPServerTimeout": 10,\n        "ConnectionSecurity": "",\n        "SendPushNotifications": false,\n        "PushNotificationServer": "",\n        "PushNotificationContents": "full",\n        "PushNotificationBuffer": 1000,\n        "EnableEmailBatching": false,\n        "EmailBatchingBufferSize": 256,\n        "EmailBatchingInterval": 30,\n        "EnablePreviewModeBanner": true,\n        "SkipServerCertificateVerification": false,\n        "EmailNotificationContentsType": "full",\n        "LoginButtonColor": "#0000",\n        "LoginButtonBorderColor": "#2389D7",\n        "LoginButtonTextColor": "#2389D7"\n    },\n    "RateLimitSettings": {\n        "Enable": false,\n        "PerSec": 10,\n        "MaxBurst": 100,\n        "MemoryStoreSize": 10000,\n        "VaryByRemoteAddr": true,\n        "VaryByUser": false,\n        "VaryByHeader": ""\n    },\n    "PrivacySettings": {\n        "ShowEmailAddress": true,\n        "ShowFullName": true\n    },\n    "SupportSettings": {\n        "TermsOfServiceLink": "https://mattermost.com/pl/terms-of-use/",\n        "PrivacyPolicyLink": "https://mattermost.com/pl/privacy-policy/",\n        "AboutLink": "https://mattermost.com/pl/about-mattermost",\n        "HelpLink": "https://mattermost.com/pl/help/",\n        "ReportAProblemLink": "https://mattermost.com/pl/report-a-bug",\n        "ForgotPasswordLink": "",\n        "SupportEmail": "",\n        "CustomTermsOfServiceEnabled": false,\n        "CustomTermsOfServiceReAcceptancePeriod": 365,\n        "EnableAskCommunityLink": true\n    },\n    "AnnouncementSettings": {\n        "EnableBanner": false,\n        "BannerText": "",\n        "BannerColor": "#f2a93b",\n        "BannerTextColor": "#333333",\n        "AllowBannerDismissal": true,\n        "AdminNoticesEnabled": true,\n        "UserNoticesEnabled": true,\n        "NoticesURL": "https://notices.mattermost.com/",\n        "NoticesFetchFrequency": 3600,\n        "NoticesSkipCache": false\n    },\n    "ThemeSettings": {\n        "EnableThemeSelection": true,\n        "DefaultTheme": "default",\n        "AllowCustomThemes": true,\n        "AllowedThemes": []\n    },\n    "GitLabSettings": {\n        "Enable": false,\n        "Secret": "",\n        "Id": "",\n        "Scope": "",\n        "AuthEndpoint": "",\n        "TokenEndpoint": "",\n        "UserAPIEndpoint": "",\n        "DiscoveryEndpoint": "",\n        "ButtonText": "",\n        "ButtonColor": ""\n    },\n    "GoogleSettings": {\n        "Enable": false,\n        "Secret": "",\n        "Id": "",\n        "Scope": "profile email",\n        "AuthEndpoint": "https://accounts.google.com/o/oauth2/v2/auth",\n        "TokenEndpoint": "https://www.googleapis.com/oauth2/v4/token",\n        "UserAPIEndpoint": "https://people.googleapis.com/v1/people/me?personFields=names,emailAddresses,nicknames,metadata",\n        "DiscoveryEndpoint": "",\n        "ButtonText": "",\n        "ButtonColor": ""\n    },\n    "Office365Settings": {\n        "Enable": false,\n        "Secret": "",\n        "Id": "",\n        "Scope": "User.Read",\n        "AuthEndpoint": "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",\n        "TokenEndpoint": "https://login.microsoftonline.com/common/oauth2/v2.0/token",\n        "UserAPIEndpoint": "https://graph.microsoft.com/v1.0/me",\n        "DiscoveryEndpoint": "",\n        "DirectoryId": ""\n    },\n    "OpenIdSettings": {\n        "Enable": false,\n        "Secret": "",\n        "Id": "",\n        "Scope": "profile openid email",\n        "AuthEndpoint": "",\n        "TokenEndpoint": "",\n        "UserAPIEndpoint": "",\n        "DiscoveryEndpoint": "",\n        "ButtonText": "",\n        "ButtonColor": "#145DBF"\n    },\n    "LdapSettings": {\n        "Enable": false,\n        "EnableSync": false,\n        "LdapServer": "",\n        "LdapPort": 389,\n        "ConnectionSecurity": "",\n        "BaseDN": "",\n        "BindUsername": "",\n        "BindPassword": "",\n        "MaximumLoginAttempts": 10,\n        "UserFilter": "",\n        "GroupFilter": "",\n        "GuestFilter": "",\n        "EnableAdminFilter": false,\n        "AdminFilter": "",\n        "GroupDisplayNameAttribute": "",\n        "GroupIdAttribute": "",\n        "FirstNameAttribute": "",\n        "LastNameAttribute": "",\n        "EmailAttribute": "",\n        "UsernameAttribute": "",\n        "NicknameAttribute": "",\n        "IdAttribute": "",\n        "PositionAttribute": "",\n        "LoginIdAttribute": "",\n        "PictureAttribute": "",\n        "SyncIntervalMinutes": 60,\n        "SkipCertificateVerification": false,\n        "PublicCertificateFile": "",\n        "PrivateKeyFile": "",\n        "QueryTimeout": 60,\n        "MaxPageSize": 0,\n        "LoginFieldName": "",\n        "LoginButtonColor": "#0000",\n        "LoginButtonBorderColor": "#2389D7",\n        "LoginButtonTextColor": "#2389D7"\n    },\n    "ComplianceSettings": {\n        "Enable": false,\n        "Directory": "./data/",\n        "EnableDaily": false,\n        "BatchSize": 30000\n    },\n    "LocalizationSettings": {\n        "DefaultServerLocale": "en",\n        "DefaultClientLocale": "en",\n        "AvailableLocales": "",\n        "EnableExperimentalLocales": false\n    },\n    "SamlSettings": {\n        "Enable": false,\n        "EnableSyncWithLdap": false,\n        "EnableSyncWithLdapIncludeAuth": false,\n        "IgnoreGuestsLdapSync": false,\n        "Verify": true,\n        "Encrypt": true,\n        "SignRequest": false,\n        "IdpURL": "",\n        "IdpDescriptorURL": "",\n        "IdpMetadataURL": "",\n        "ServiceProviderIdentifier": "",\n        "AssertionConsumerServiceURL": "",\n        "SignatureAlgorithm": "RSAwithSHA1",\n        "CanonicalAlgorithm": "Canonical1.0",\n        "ScopingIDPProviderId": "",\n        "ScopingIDPName": "",\n        "IdpCertificateFile": "",\n        "PublicCertificateFile": "",\n        "PrivateKeyFile": "",\n        "IdAttribute": "",\n        "GuestAttribute": "",\n        "EnableAdminAttribute": false,\n        "AdminAttribute": "",\n        "FirstNameAttribute": "",\n        "LastNameAttribute": "",\n        "EmailAttribute": "",\n        "UsernameAttribute": "",\n        "NicknameAttribute": "",\n        "LocaleAttribute": "",\n        "PositionAttribute": "",\n        "LoginButtonText": "SAML",\n        "LoginButtonColor": "#34a28b",\n        "LoginButtonBorderColor": "#2389D7",\n        "LoginButtonTextColor": "#ffffff"\n    },\n    "NativeAppSettings": {\n        "AppCustomURLSchemes": [\n            "mmauth://",\n            "mmauthbeta://"\n        ],\n        "AppDownloadLink": "https://mattermost.com/pl/download-apps",\n        "AndroidAppDownloadLink": "https://mattermost.com/pl/android-app/",\n        "IosAppDownloadLink": "https://mattermost.com/pl/ios-app/",\n        "MobileExternalBrowser": false\n    },\n    "CacheSettings": {\n        "CacheType": "lru",\n        "RedisAddress": "",\n        "RedisPassword": "********************************",\n        "RedisDB": -1,\n        "DisableClientCache": false\n    },\n    "ClusterSettings": {\n        "Enable": false,\n        "ClusterName": "",\n        "OverrideHostname": "",\n        "NetworkInterface": "",\n        "BindAddress": "",\n        "AdvertiseAddress": "",\n        "UseIPAddress": true,\n        "EnableGossipCompression": true,\n        "EnableExperimentalGossipEncryption": false,\n        "ReadOnlyConfig": true,\n        "GossipPort": 8074\n    },\n    "MetricsSettings": {\n        "Enable": false,\n        "BlockProfileRate": 0,\n        "ListenAddress": ":8067",\n        "EnableClientMetrics": true,\n        "EnableNotificationMetrics": true\n    },\n    "ExperimentalSettings": {\n        "ClientSideCertEnable": false,\n        "ClientSideCertCheck": "secondary",\n        "LinkMetadataTimeoutMilliseconds": 5000,\n        "RestrictSystemAdmin": false,\n        "EnableSharedChannels": false,\n        "EnableRemoteClusterService": false,\n        "DisableAppBar": false,\n        "DisableRefetchingOnBrowserFocus": false,\n        "DelayChannelAutocomplete": false,\n        "DisableWakeUpReconnectHandler": false,\n        "UsersStatusAndProfileFetchingPollIntervalMilliseconds": 3000,\n        "YoutubeReferrerPolicy": false\n    },\n    "AnalyticsSettings": {\n        "MaxUsersForStatistics": 2500\n    },\n    "ElasticsearchSettings": {\n        "ConnectionURL": "http://localhost:9200",\n        "Backend": "elasticsearch",\n        "Username": "elastic",\n        "Password": "changeme",\n        "EnableIndexing": false,\n        "EnableSearching": false,\n        "EnableAutocomplete": false,\n        "Sniff": true,\n        "PostIndexReplicas": 1,\n        "PostIndexShards": 1,\n        "ChannelIndexReplicas": 1,\n        "ChannelIndexShards": 1,\n        "UserIndexReplicas": 1,\n        "UserIndexShards": 1,\n        "AggregatePostsAfterDays": 365,\n        "PostsAggregatorJobStartTime": "03:00",\n        "IndexPrefix": "",\n        "LiveIndexingBatchSize": 10,\n        "BatchSize": 10000,\n        "RequestTimeoutSeconds": 30,\n        "SkipTLSVerification": false,\n        "CA": "",\n        "ClientCert": "",\n        "ClientKey": "",\n        "Trace": "",\n        "IgnoredPurgeIndexes": ""\n    },\n    "BleveSettings": {\n        "IndexDir": "",\n        "EnableIndexing": false,\n        "EnableSearching": false,\n        "EnableAutocomplete": false,\n        "BatchSize": 10000\n    },\n    "DataRetentionSettings": {\n        "EnableMessageDeletion": false,\n        "EnableFileDeletion": false,\n        "EnableBoardsDeletion": false,\n        "MessageRetentionDays": 365,\n        "MessageRetentionHours": 0,\n        "FileRetentionDays": 365,\n        "FileRetentionHours": 0,\n        "BoardsRetentionDays": 365,\n        "DeletionJobStartTime": "02:00",\n        "BatchSize": 3000,\n        "TimeBetweenBatchesMilliseconds": 100,\n        "RetentionIdsBatchSize": 100\n    },\n    "MessageExportSettings": {\n        "EnableExport": false,\n        "ExportFormat": "actiance",\n        "DailyRunTime": "01:00",\n        "ExportFromTimestamp": 0,\n        "BatchSize": 10000,\n        "DownloadExportResults": false,\n        "ChannelBatchSize": 100,\n        "ChannelHistoryBatchSize": 10,\n        "GlobalRelaySettings": {\n            "CustomerType": "A9",\n            "SMTPUsername": "",\n            "SMTPPassword": "",\n            "EmailAddress": "",\n            "SMTPServerTimeout": 1800,\n            "CustomSMTPServerName": "",\n            "CustomSMTPPort": "25"\n        }\n    },\n    "JobSettings": {\n        "RunJobs": true,\n        "RunScheduler": true,\n        "CleanupJobsThresholdDays": -1,\n        "CleanupConfigThresholdDays": -1\n    },\n    "PluginSettings": {\n        "Enable": true,\n        "EnableUploads": false,\n        "AllowInsecureDownloadURL": false,\n        "EnableHealthCheck": true,\n        "Directory": "./plugins",\n        "ClientDirectory": "./client/plugins",\n        "Plugins": {\n            "playbooks": {\n                "BotUserID": "oi9jhtfswpbtbfotpsuuj71zuc"\n            }\n        },\n        "PluginStates": {\n            "com.mattermost.calls": {\n                "Enable": true\n            },\n            "com.mattermost.nps": {\n                "Enable": false\n            },\n            "mattermost-ai": {\n                "Enable": true\n            },\n            "playbooks": {\n                "Enable": true\n            }\n        },\n        "EnableMarketplace": true,\n        "EnableRemoteMarketplace": true,\n        "AutomaticPrepackagedPlugins": true,\n        "RequirePluginSignature": false,\n        "MarketplaceURL": "https://api.integrations.mattermost.com",\n        "SignaturePublicKeyFiles": [],\n        "ChimeraOAuthProxyURL": ""\n    },\n    "DisplaySettings": {\n        "CustomURLSchemes": [],\n        "MaxMarkdownNodes": 0\n    },\n    "GuestAccountsSettings": {\n        "Enable": false,\n        "HideTags": false,\n        "AllowEmailAccounts": true,\n        "EnforceMultifactorAuthentication": false,\n        "RestrictCreationToDomains": ""\n    },\n    "ImageProxySettings": {\n        "Enable": false,\n        "ImageProxyType": "local",\n        "RemoteImageProxyURL": "",\n        "RemoteImageProxyOptions": ""\n    },\n    "CloudSettings": {\n        "CWSURL": "https://customers.mattermost.com",\n        "CWSAPIURL": "https://portal.internal.prod.cloud.mattermost.com",\n        "CWSMock": false,\n        "Disable": false\n    },\n    "ImportSettings": {\n        "Directory": "./import",\n        "RetentionDays": 30\n    },\n    "ExportSettings": {\n        "Directory": "./export",\n        "RetentionDays": 30\n    },\n    "WranglerSettings": {\n        "PermittedWranglerRoles": [],\n        "AllowedEmailDomain": [],\n        "MoveThreadMaxCount": 100,\n        "MoveThreadToAnotherTeamEnable": false,\n        "MoveThreadFromPrivateChannelEnable": false,\n        "MoveThreadFromDirectMessageChannelEnable": false,\n        "MoveThreadFromGroupMessageChannelEnable": false\n    },\n    "ConnectedWorkspacesSettings": {\n        "EnableSharedChannels": false,\n        "EnableRemoteClusterService": false,\n        "DisableSharedChannelsStatusSync": false,\n        "MaxPostsPerSync": 50\n    }\n}	1771646034041	\N	a09936d2bf26ff0deababa36f7eb37d2daa3efcffd61550b4925f43cfe3380cd
y6c33wj343g68pewfgxjb9jq5h	{\n    "ServiceSettings": {\n        "SiteURL": "",\n        "WebsocketURL": "",\n        "LicenseFileLocation": "",\n        "ListenAddress": ":8065",\n        "ConnectionSecurity": "",\n        "TLSCertFile": "",\n        "TLSKeyFile": "",\n        "TLSMinVer": "1.2",\n        "TLSStrictTransport": false,\n        "TLSStrictTransportMaxAge": 63072000,\n        "TLSOverwriteCiphers": [],\n        "UseLetsEncrypt": false,\n        "LetsEncryptCertificateCacheFile": "./config/letsencrypt.cache",\n        "Forward80To443": false,\n        "TrustedProxyIPHeader": [],\n        "ReadTimeout": 300,\n        "WriteTimeout": 300,\n        "IdleTimeout": 60,\n        "MaximumLoginAttempts": 10,\n        "GoroutineHealthThreshold": -1,\n        "EnableOAuthServiceProvider": true,\n        "EnableIncomingWebhooks": true,\n        "EnableOutgoingWebhooks": true,\n        "EnableOutgoingOAuthConnections": false,\n        "EnableCommands": true,\n        "OutgoingIntegrationRequestsTimeout": 30,\n        "EnablePostUsernameOverride": false,\n        "EnablePostIconOverride": false,\n        "GoogleDeveloperKey": "",\n        "EnableLinkPreviews": true,\n        "EnablePermalinkPreviews": true,\n        "RestrictLinkPreviews": "",\n        "EnableTesting": false,\n        "EnableDeveloper": false,\n        "DeveloperFlags": "",\n        "EnableClientPerformanceDebugging": false,\n        "EnableOpenTracing": false,\n        "EnableSecurityFixAlert": true,\n        "EnableInsecureOutgoingConnections": false,\n        "AllowedUntrustedInternalConnections": "",\n        "EnableMultifactorAuthentication": false,\n        "EnforceMultifactorAuthentication": false,\n        "EnableUserAccessTokens": false,\n        "AllowCorsFrom": "",\n        "CorsExposedHeaders": "",\n        "CorsAllowCredentials": false,\n        "CorsDebug": false,\n        "AllowCookiesForSubdomains": false,\n        "ExtendSessionLengthWithActivity": false,\n        "TerminateSessionsOnPasswordChange": false,\n        "SessionLengthWebInDays": 180,\n        "SessionLengthWebInHours": 4320,\n        "SessionLengthMobileInDays": 180,\n        "SessionLengthMobileInHours": 4320,\n        "SessionLengthSSOInDays": 30,\n        "SessionLengthSSOInHours": 720,\n        "SessionCacheInMinutes": 10,\n        "SessionIdleTimeoutInMinutes": 43200,\n        "WebsocketSecurePort": 443,\n        "WebsocketPort": 80,\n        "WebserverMode": "gzip",\n        "EnableGifPicker": true,\n        "GiphySdkKey": "",\n        "EnableCustomEmoji": true,\n        "EnableEmojiPicker": true,\n        "PostEditTimeLimit": -1,\n        "TimeBetweenUserTypingUpdatesMilliseconds": 5000,\n        "EnablePostSearch": true,\n        "EnableFileSearch": true,\n        "MinimumHashtagLength": 3,\n        "EnableUserTypingMessages": true,\n        "EnableChannelViewedMessages": true,\n        "EnableUserStatuses": true,\n        "ExperimentalEnableAuthenticationTransfer": true,\n        "ClusterLogTimeoutMilliseconds": 2000,\n        "EnableTutorial": true,\n        "EnableOnboardingFlow": true,\n        "ExperimentalEnableDefaultChannelLeaveJoinMessages": true,\n        "ExperimentalGroupUnreadChannels": "disabled",\n        "EnableAPITeamDeletion": false,\n        "EnableAPITriggerAdminNotifications": false,\n        "EnableAPIUserDeletion": false,\n        "EnableAPIPostDeletion": false,\n        "EnableDesktopLandingPage": true,\n        "ExperimentalEnableHardenedMode": false,\n        "ExperimentalStrictCSRFEnforcement": false,\n        "EnableEmailInvitations": true,\n        "DisableBotsWhenOwnerIsDeactivated": true,\n        "EnableBotAccountCreation": false,\n        "EnableSVGs": true,\n        "EnableLatex": true,\n        "EnableInlineLatex": true,\n        "PostPriority": true,\n        "AllowPersistentNotifications": true,\n        "AllowPersistentNotificationsForGuests": false,\n        "PersistentNotificationIntervalMinutes": 5,\n        "PersistentNotificationMaxCount": 6,\n        "PersistentNotificationMaxRecipients": 5,\n        "EnableAPIChannelDeletion": false,\n        "EnableLocalMode": false,\n        "LocalModeSocketLocation": "/var/tmp/mattermost_local.socket",\n        "EnableAWSMetering": false,\n        "SplitKey": "",\n        "FeatureFlagSyncIntervalSeconds": 30,\n        "DebugSplit": false,\n        "ThreadAutoFollow": true,\n        "CollapsedThreads": "always_on",\n        "ManagedResourcePaths": "",\n        "EnableCustomGroups": true,\n        "AllowSyncedDrafts": true,\n        "UniqueEmojiReactionLimitPerPost": 50,\n        "RefreshPostStatsRunTime": "00:00",\n        "MaximumPayloadSizeBytes": 300000,\n        "MaximumURLLength": 2048,\n        "ScheduledPosts": true,\n        "EnableWebHubChannelIteration": false\n    },\n    "TeamSettings": {\n        "SiteName": "Mattermost",\n        "MaxUsersPerTeam": 50,\n        "EnableJoinLeaveMessageByDefault": true,\n        "EnableUserCreation": true,\n        "EnableOpenServer": false,\n        "EnableUserDeactivation": false,\n        "RestrictCreationToDomains": "",\n        "EnableCustomUserStatuses": true,\n        "EnableCustomBrand": false,\n        "CustomBrandText": "",\n        "CustomDescriptionText": "",\n        "RestrictDirectMessage": "any",\n        "EnableLastActiveTime": true,\n        "UserStatusAwayTimeout": 300,\n        "MaxChannelsPerTeam": 2000,\n        "MaxNotificationsPerChannel": 1000,\n        "EnableConfirmNotificationsToChannel": true,\n        "TeammateNameDisplay": "username",\n        "ExperimentalViewArchivedChannels": true,\n        "ExperimentalEnableAutomaticReplies": false,\n        "LockTeammateNameDisplay": false,\n        "ExperimentalPrimaryTeam": "",\n        "ExperimentalDefaultChannels": []\n    },\n    "ClientRequirements": {\n        "AndroidLatestVersion": "",\n        "AndroidMinVersion": "",\n        "IosLatestVersion": "",\n        "IosMinVersion": ""\n    },\n    "SqlSettings": {\n        "DriverName": "postgres",\n        "DataSource": "postgres://mattermost_user:mattermost_pw@postgres.zoo/mattermost_db?sslmode=disable",\n        "DataSourceReplicas": [],\n        "DataSourceSearchReplicas": [],\n        "MaxIdleConns": 20,\n        "ConnMaxLifetimeMilliseconds": 3600000,\n        "ConnMaxIdleTimeMilliseconds": 300000,\n        "MaxOpenConns": 300,\n        "Trace": false,\n        "AtRestEncryptKey": "51z7tarrgmz9wzcnt8rumnzkqsdukrxr",\n        "QueryTimeout": 30,\n        "DisableDatabaseSearch": false,\n        "MigrationsStatementTimeoutSeconds": 100000,\n        "ReplicaLagSettings": [],\n        "ReplicaMonitorIntervalSeconds": 5\n    },\n    "LogSettings": {\n        "EnableConsole": true,\n        "ConsoleLevel": "DEBUG",\n        "ConsoleJson": true,\n        "EnableColor": false,\n        "EnableFile": true,\n        "FileLevel": "INFO",\n        "FileJson": true,\n        "FileLocation": "",\n        "EnableWebhookDebugging": true,\n        "EnableDiagnostics": true,\n        "VerboseDiagnostics": false,\n        "EnableSentry": true,\n        "AdvancedLoggingJSON": null,\n        "MaxFieldSize": 2048\n    },\n    "ExperimentalAuditSettings": {\n        "FileEnabled": false,\n        "FileName": "",\n        "FileMaxSizeMB": 100,\n        "FileMaxAgeDays": 0,\n        "FileMaxBackups": 0,\n        "FileCompress": false,\n        "FileMaxQueueSize": 1000,\n        "AdvancedLoggingJSON": null\n    },\n    "NotificationLogSettings": {\n        "EnableConsole": true,\n        "ConsoleLevel": "DEBUG",\n        "ConsoleJson": true,\n        "EnableColor": false,\n        "EnableFile": true,\n        "FileLevel": "INFO",\n        "FileJson": true,\n        "FileLocation": "",\n        "AdvancedLoggingJSON": null\n    },\n    "PasswordSettings": {\n        "MinimumLength": 8,\n        "Lowercase": false,\n        "Number": false,\n        "Uppercase": false,\n        "Symbol": false,\n        "EnableForgotLink": true\n    },\n    "FileSettings": {\n        "EnableFileAttachments": true,\n        "EnableMobileUpload": true,\n        "EnableMobileDownload": true,\n        "MaxFileSize": 104857600,\n        "MaxImageResolution": 33177600,\n        "MaxImageDecoderConcurrency": -1,\n        "DriverName": "local",\n        "Directory": "./data/",\n        "EnablePublicLink": false,\n        "ExtractContent": true,\n        "ArchiveRecursion": false,\n        "PublicLinkSalt": "qteo68ysr89by8wjnarggb53tguak4eo",\n        "InitialFont": "nunito-bold.ttf",\n        "AmazonS3AccessKeyId": "",\n        "AmazonS3SecretAccessKey": "",\n        "AmazonS3Bucket": "",\n        "AmazonS3PathPrefix": "",\n        "AmazonS3Region": "",\n        "AmazonS3Endpoint": "s3.amazonaws.com",\n        "AmazonS3SSL": true,\n        "AmazonS3SignV2": false,\n        "AmazonS3SSE": false,\n        "AmazonS3Trace": false,\n        "AmazonS3RequestTimeoutMilliseconds": 30000,\n        "AmazonS3UploadPartSizeBytes": 5242880,\n        "AmazonS3StorageClass": "",\n        "DedicatedExportStore": false,\n        "ExportDriverName": "local",\n        "ExportDirectory": "./data/",\n        "ExportAmazonS3AccessKeyId": "",\n        "ExportAmazonS3SecretAccessKey": "",\n        "ExportAmazonS3Bucket": "",\n        "ExportAmazonS3PathPrefix": "",\n        "ExportAmazonS3Region": "",\n        "ExportAmazonS3Endpoint": "s3.amazonaws.com",\n        "ExportAmazonS3SSL": true,\n        "ExportAmazonS3SignV2": false,\n        "ExportAmazonS3SSE": false,\n        "ExportAmazonS3Trace": false,\n        "ExportAmazonS3RequestTimeoutMilliseconds": 30000,\n        "ExportAmazonS3PresignExpiresSeconds": 21600,\n        "ExportAmazonS3UploadPartSizeBytes": 104857600,\n        "ExportAmazonS3StorageClass": ""\n    },\n    "EmailSettings": {\n        "EnableSignUpWithEmail": true,\n        "EnableSignInWithEmail": true,\n        "EnableSignInWithUsername": true,\n        "SendEmailNotifications": true,\n        "UseChannelInEmailNotifications": false,\n        "RequireEmailVerification": false,\n        "FeedbackName": "",\n        "FeedbackEmail": "test@example.com",\n        "ReplyToAddress": "test@example.com",\n        "FeedbackOrganization": "",\n        "EnableSMTPAuth": false,\n        "SMTPUsername": "",\n        "SMTPPassword": "",\n        "SMTPServer": "localhost",\n        "SMTPPort": "10025",\n        "SMTPServerTimeout": 10,\n        "ConnectionSecurity": "",\n        "SendPushNotifications": false,\n        "PushNotificationServer": "",\n        "PushNotificationContents": "full",\n        "PushNotificationBuffer": 1000,\n        "EnableEmailBatching": false,\n        "EmailBatchingBufferSize": 256,\n        "EmailBatchingInterval": 30,\n        "EnablePreviewModeBanner": true,\n        "SkipServerCertificateVerification": false,\n        "EmailNotificationContentsType": "full",\n        "LoginButtonColor": "#0000",\n        "LoginButtonBorderColor": "#2389D7",\n        "LoginButtonTextColor": "#2389D7"\n    },\n    "RateLimitSettings": {\n        "Enable": false,\n        "PerSec": 10,\n        "MaxBurst": 100,\n        "MemoryStoreSize": 10000,\n        "VaryByRemoteAddr": true,\n        "VaryByUser": false,\n        "VaryByHeader": ""\n    },\n    "PrivacySettings": {\n        "ShowEmailAddress": true,\n        "ShowFullName": true\n    },\n    "SupportSettings": {\n        "TermsOfServiceLink": "https://mattermost.com/pl/terms-of-use/",\n        "PrivacyPolicyLink": "https://mattermost.com/pl/privacy-policy/",\n        "AboutLink": "https://mattermost.com/pl/about-mattermost",\n        "HelpLink": "https://mattermost.com/pl/help/",\n        "ReportAProblemLink": "https://mattermost.com/pl/report-a-bug",\n        "ForgotPasswordLink": "",\n        "SupportEmail": "",\n        "CustomTermsOfServiceEnabled": false,\n        "CustomTermsOfServiceReAcceptancePeriod": 365,\n        "EnableAskCommunityLink": true\n    },\n    "AnnouncementSettings": {\n        "EnableBanner": false,\n        "BannerText": "",\n        "BannerColor": "#f2a93b",\n        "BannerTextColor": "#333333",\n        "AllowBannerDismissal": true,\n        "AdminNoticesEnabled": true,\n        "UserNoticesEnabled": true,\n        "NoticesURL": "https://notices.mattermost.com/",\n        "NoticesFetchFrequency": 3600,\n        "NoticesSkipCache": false\n    },\n    "ThemeSettings": {\n        "EnableThemeSelection": true,\n        "DefaultTheme": "default",\n        "AllowCustomThemes": true,\n        "AllowedThemes": []\n    },\n    "GitLabSettings": {\n        "Enable": false,\n        "Secret": "",\n        "Id": "",\n        "Scope": "",\n        "AuthEndpoint": "",\n        "TokenEndpoint": "",\n        "UserAPIEndpoint": "",\n        "DiscoveryEndpoint": "",\n        "ButtonText": "",\n        "ButtonColor": ""\n    },\n    "GoogleSettings": {\n        "Enable": false,\n        "Secret": "",\n        "Id": "",\n        "Scope": "profile email",\n        "AuthEndpoint": "https://accounts.google.com/o/oauth2/v2/auth",\n        "TokenEndpoint": "https://www.googleapis.com/oauth2/v4/token",\n        "UserAPIEndpoint": "https://people.googleapis.com/v1/people/me?personFields=names,emailAddresses,nicknames,metadata",\n        "DiscoveryEndpoint": "",\n        "ButtonText": "",\n        "ButtonColor": ""\n    },\n    "Office365Settings": {\n        "Enable": false,\n        "Secret": "",\n        "Id": "",\n        "Scope": "User.Read",\n        "AuthEndpoint": "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",\n        "TokenEndpoint": "https://login.microsoftonline.com/common/oauth2/v2.0/token",\n        "UserAPIEndpoint": "https://graph.microsoft.com/v1.0/me",\n        "DiscoveryEndpoint": "",\n        "DirectoryId": ""\n    },\n    "OpenIdSettings": {\n        "Enable": false,\n        "Secret": "",\n        "Id": "",\n        "Scope": "profile openid email",\n        "AuthEndpoint": "",\n        "TokenEndpoint": "",\n        "UserAPIEndpoint": "",\n        "DiscoveryEndpoint": "",\n        "ButtonText": "",\n        "ButtonColor": "#145DBF"\n    },\n    "LdapSettings": {\n        "Enable": false,\n        "EnableSync": false,\n        "LdapServer": "",\n        "LdapPort": 389,\n        "ConnectionSecurity": "",\n        "BaseDN": "",\n        "BindUsername": "",\n        "BindPassword": "",\n        "MaximumLoginAttempts": 10,\n        "UserFilter": "",\n        "GroupFilter": "",\n        "GuestFilter": "",\n        "EnableAdminFilter": false,\n        "AdminFilter": "",\n        "GroupDisplayNameAttribute": "",\n        "GroupIdAttribute": "",\n        "FirstNameAttribute": "",\n        "LastNameAttribute": "",\n        "EmailAttribute": "",\n        "UsernameAttribute": "",\n        "NicknameAttribute": "",\n        "IdAttribute": "",\n        "PositionAttribute": "",\n        "LoginIdAttribute": "",\n        "PictureAttribute": "",\n        "SyncIntervalMinutes": 60,\n        "SkipCertificateVerification": false,\n        "PublicCertificateFile": "",\n        "PrivateKeyFile": "",\n        "QueryTimeout": 60,\n        "MaxPageSize": 0,\n        "LoginFieldName": "",\n        "LoginButtonColor": "#0000",\n        "LoginButtonBorderColor": "#2389D7",\n        "LoginButtonTextColor": "#2389D7"\n    },\n    "ComplianceSettings": {\n        "Enable": false,\n        "Directory": "./data/",\n        "EnableDaily": false,\n        "BatchSize": 30000\n    },\n    "LocalizationSettings": {\n        "DefaultServerLocale": "en",\n        "DefaultClientLocale": "en",\n        "AvailableLocales": "",\n        "EnableExperimentalLocales": false\n    },\n    "SamlSettings": {\n        "Enable": false,\n        "EnableSyncWithLdap": false,\n        "EnableSyncWithLdapIncludeAuth": false,\n        "IgnoreGuestsLdapSync": false,\n        "Verify": true,\n        "Encrypt": true,\n        "SignRequest": false,\n        "IdpURL": "",\n        "IdpDescriptorURL": "",\n        "IdpMetadataURL": "",\n        "ServiceProviderIdentifier": "",\n        "AssertionConsumerServiceURL": "",\n        "SignatureAlgorithm": "RSAwithSHA1",\n        "CanonicalAlgorithm": "Canonical1.0",\n        "ScopingIDPProviderId": "",\n        "ScopingIDPName": "",\n        "IdpCertificateFile": "",\n        "PublicCertificateFile": "",\n        "PrivateKeyFile": "",\n        "IdAttribute": "",\n        "GuestAttribute": "",\n        "EnableAdminAttribute": false,\n        "AdminAttribute": "",\n        "FirstNameAttribute": "",\n        "LastNameAttribute": "",\n        "EmailAttribute": "",\n        "UsernameAttribute": "",\n        "NicknameAttribute": "",\n        "LocaleAttribute": "",\n        "PositionAttribute": "",\n        "LoginButtonText": "SAML",\n        "LoginButtonColor": "#34a28b",\n        "LoginButtonBorderColor": "#2389D7",\n        "LoginButtonTextColor": "#ffffff"\n    },\n    "NativeAppSettings": {\n        "AppCustomURLSchemes": [\n            "mmauth://",\n            "mmauthbeta://"\n        ],\n        "AppDownloadLink": "https://mattermost.com/pl/download-apps",\n        "AndroidAppDownloadLink": "https://mattermost.com/pl/android-app/",\n        "IosAppDownloadLink": "https://mattermost.com/pl/ios-app/",\n        "MobileExternalBrowser": false\n    },\n    "CacheSettings": {\n        "CacheType": "lru",\n        "RedisAddress": "",\n        "RedisPassword": "********************************",\n        "RedisDB": -1,\n        "DisableClientCache": false\n    },\n    "ClusterSettings": {\n        "Enable": false,\n        "ClusterName": "",\n        "OverrideHostname": "",\n        "NetworkInterface": "",\n        "BindAddress": "",\n        "AdvertiseAddress": "",\n        "UseIPAddress": true,\n        "EnableGossipCompression": true,\n        "EnableExperimentalGossipEncryption": false,\n        "ReadOnlyConfig": true,\n        "GossipPort": 8074\n    },\n    "MetricsSettings": {\n        "Enable": false,\n        "BlockProfileRate": 0,\n        "ListenAddress": ":8067",\n        "EnableClientMetrics": true,\n        "EnableNotificationMetrics": true\n    },\n    "ExperimentalSettings": {\n        "ClientSideCertEnable": false,\n        "ClientSideCertCheck": "secondary",\n        "LinkMetadataTimeoutMilliseconds": 5000,\n        "RestrictSystemAdmin": false,\n        "EnableSharedChannels": false,\n        "EnableRemoteClusterService": false,\n        "DisableAppBar": false,\n        "DisableRefetchingOnBrowserFocus": false,\n        "DelayChannelAutocomplete": false,\n        "DisableWakeUpReconnectHandler": false,\n        "UsersStatusAndProfileFetchingPollIntervalMilliseconds": 3000,\n        "YoutubeReferrerPolicy": false\n    },\n    "AnalyticsSettings": {\n        "MaxUsersForStatistics": 2500\n    },\n    "ElasticsearchSettings": {\n        "ConnectionURL": "http://localhost:9200",\n        "Backend": "elasticsearch",\n        "Username": "elastic",\n        "Password": "changeme",\n        "EnableIndexing": false,\n        "EnableSearching": false,\n        "EnableAutocomplete": false,\n        "Sniff": true,\n        "PostIndexReplicas": 1,\n        "PostIndexShards": 1,\n        "ChannelIndexReplicas": 1,\n        "ChannelIndexShards": 1,\n        "UserIndexReplicas": 1,\n        "UserIndexShards": 1,\n        "AggregatePostsAfterDays": 365,\n        "PostsAggregatorJobStartTime": "03:00",\n        "IndexPrefix": "",\n        "LiveIndexingBatchSize": 10,\n        "BatchSize": 10000,\n        "RequestTimeoutSeconds": 30,\n        "SkipTLSVerification": false,\n        "CA": "",\n        "ClientCert": "",\n        "ClientKey": "",\n        "Trace": "",\n        "IgnoredPurgeIndexes": ""\n    },\n    "BleveSettings": {\n        "IndexDir": "",\n        "EnableIndexing": false,\n        "EnableSearching": false,\n        "EnableAutocomplete": false,\n        "BatchSize": 10000\n    },\n    "DataRetentionSettings": {\n        "EnableMessageDeletion": false,\n        "EnableFileDeletion": false,\n        "EnableBoardsDeletion": false,\n        "MessageRetentionDays": 365,\n        "MessageRetentionHours": 0,\n        "FileRetentionDays": 365,\n        "FileRetentionHours": 0,\n        "BoardsRetentionDays": 365,\n        "DeletionJobStartTime": "02:00",\n        "BatchSize": 3000,\n        "TimeBetweenBatchesMilliseconds": 100,\n        "RetentionIdsBatchSize": 100\n    },\n    "MessageExportSettings": {\n        "EnableExport": false,\n        "ExportFormat": "actiance",\n        "DailyRunTime": "01:00",\n        "ExportFromTimestamp": 0,\n        "BatchSize": 10000,\n        "DownloadExportResults": false,\n        "ChannelBatchSize": 100,\n        "ChannelHistoryBatchSize": 10,\n        "GlobalRelaySettings": {\n            "CustomerType": "A9",\n            "SMTPUsername": "",\n            "SMTPPassword": "",\n            "EmailAddress": "",\n            "SMTPServerTimeout": 1800,\n            "CustomSMTPServerName": "",\n            "CustomSMTPPort": "25"\n        }\n    },\n    "JobSettings": {\n        "RunJobs": true,\n        "RunScheduler": true,\n        "CleanupJobsThresholdDays": -1,\n        "CleanupConfigThresholdDays": -1\n    },\n    "PluginSettings": {\n        "Enable": true,\n        "EnableUploads": false,\n        "AllowInsecureDownloadURL": false,\n        "EnableHealthCheck": true,\n        "Directory": "./plugins",\n        "ClientDirectory": "./client/plugins",\n        "Plugins": {\n            "playbooks": {\n                "BotUserID": "oi9jhtfswpbtbfotpsuuj71zuc"\n            }\n        },\n        "PluginStates": {\n            "com.mattermost.calls": {\n                "Enable": true\n            },\n            "com.mattermost.nps": {\n                "Enable": false\n            },\n            "mattermost-ai": {\n                "Enable": true\n            },\n            "playbooks": {\n                "Enable": false\n            }\n        },\n        "EnableMarketplace": true,\n        "EnableRemoteMarketplace": true,\n        "AutomaticPrepackagedPlugins": true,\n        "RequirePluginSignature": false,\n        "MarketplaceURL": "https://api.integrations.mattermost.com",\n        "SignaturePublicKeyFiles": [],\n        "ChimeraOAuthProxyURL": ""\n    },\n    "DisplaySettings": {\n        "CustomURLSchemes": [],\n        "MaxMarkdownNodes": 0\n    },\n    "GuestAccountsSettings": {\n        "Enable": false,\n        "HideTags": false,\n        "AllowEmailAccounts": true,\n        "EnforceMultifactorAuthentication": false,\n        "RestrictCreationToDomains": ""\n    },\n    "ImageProxySettings": {\n        "Enable": false,\n        "ImageProxyType": "local",\n        "RemoteImageProxyURL": "",\n        "RemoteImageProxyOptions": ""\n    },\n    "CloudSettings": {\n        "CWSURL": "https://customers.mattermost.com",\n        "CWSAPIURL": "https://portal.internal.prod.cloud.mattermost.com",\n        "CWSMock": false,\n        "Disable": false\n    },\n    "ImportSettings": {\n        "Directory": "./import",\n        "RetentionDays": 30\n    },\n    "ExportSettings": {\n        "Directory": "./export",\n        "RetentionDays": 30\n    },\n    "WranglerSettings": {\n        "PermittedWranglerRoles": [],\n        "AllowedEmailDomain": [],\n        "MoveThreadMaxCount": 100,\n        "MoveThreadToAnotherTeamEnable": false,\n        "MoveThreadFromPrivateChannelEnable": false,\n        "MoveThreadFromDirectMessageChannelEnable": false,\n        "MoveThreadFromGroupMessageChannelEnable": false\n    },\n    "ConnectedWorkspacesSettings": {\n        "EnableSharedChannels": false,\n        "EnableRemoteClusterService": false,\n        "DisableSharedChannelsStatusSync": false,\n        "MaxPostsPerSync": 50\n    }\n}	1771646034376	t	6b6b637ecfc916342689ca7051646356d10cfab24d5a710beda13a14b6a60a65
\.


--
-- Data for Name: db_config_migrations; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.db_config_migrations (version, name) FROM stdin;
1	create_configurations
2	create_configuration_files
3	update_configurations_sha
\.


--
-- Data for Name: db_lock; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.db_lock (id, expireat) FROM stdin;
\.


--
-- Data for Name: db_migrations; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.db_migrations (version, name) FROM stdin;
1	create_teams
2	create_team_members
3	create_cluster_discovery
4	create_command_webhooks
5	create_compliances
6	create_emojis
7	create_user_groups
8	create_group_members
9	create_group_teams
10	create_group_channels
11	create_link_metadata
12	create_commands
13	create_incoming_webhooks
14	create_outgoing_webhooks
15	create_systems
16	create_reactions
17	create_roles
18	create_schemes
19	create_licenses
20	create_posts
21	create_product_notice_view_state
22	create_sessions
23	create_terms_of_service
24	create_audits
25	create_oauth_access_data
26	create_preferences
27	create_status
28	create_tokens
29	create_bots
30	create_user_access_tokens
31	create_remote_clusters
32	create_sharedchannels
33	create_sidebar_channels
34	create_oauthauthdata
35	create_sharedchannelattachments
36	create_sharedchannelusers
37	create_sharedchannelremotes
38	create_jobs
39	create_channel_member_history
40	create_sidebar_categories
41	create_upload_sessions
42	create_threads
43	thread_memberships
44	create_user_terms_of_service
45	create_plugin_key_value_store
46	create_users
47	create_file_info
48	create_oauth_apps
49	create_channels
50	create_channelmembers
51	create_msg_root_count
52	create_public_channels
53	create_retention_policies
54	create_crt_channelmembership_count
55	create_crt_thread_count_and_unreads
56	upgrade_channels_v6.0
57	upgrade_command_webhooks_v6.0
58	upgrade_channelmembers_v6.0
59	upgrade_users_v6.0
60	upgrade_jobs_v6.0
61	upgrade_link_metadata_v6.0
62	upgrade_sessions_v6.0
63	upgrade_threads_v6.0
64	upgrade_status_v6.0
65	upgrade_groupchannels_v6.0
66	upgrade_posts_v6.0
67	upgrade_channelmembers_v6.1
68	upgrade_teammembers_v6.1
69	upgrade_jobs_v6.1
70	upgrade_cte_v6.1
71	upgrade_sessions_v6.1
72	upgrade_schemes_v6.3
73	upgrade_plugin_key_value_store_v6.3
74	upgrade_users_v6.3
75	alter_upload_sessions_index
76	upgrade_lastrootpostat
77	upgrade_users_v6.5
78	create_oauth_mattermost_app_id
79	usergroups_displayname_index
80	posts_createat_id
81	threads_deleteat
82	upgrade_oauth_mattermost_app_id
83	threads_threaddeleteat
84	recent_searches
85	fileinfo_add_archived_column
86	add_cloud_limits_archived
87	sidebar_categories_index
88	remaining_migrations
89	add-channelid-to-reaction
90	create_enums
91	create_post_reminder
92	add_createat_to_teamembers
93	notify_admin
94	threads_teamid
95	remove_posts_parentid
96	threads_threadteamid
97	create_posts_priority
98	create_post_acknowledgements
99	create_drafts
100	add_draft_priority_column
101	create_true_up_review_history
102	posts_originalid_index
103	add_sentat_to_notifyadmin
104	upgrade_notifyadmin
105	remove_tokens
106	fileinfo_channelid
107	threadmemberships_cleanup
108	remove_orphaned_oauth_preferences
109	create_persistent_notifications
111	update_vacuuming
112	rework_desktop_tokens
113	create_retentionidsfordeletion_table
114	sharedchannelremotes_drop_nextsyncat_description
115	user_reporting_changes
116	create_outgoing_oauth_connections
117	msteams_shared_channels
118	create_index_poststats
119	msteams_shared_channels_opts
120	create_channelbookmarks_table
121	remove_true_up_review_history
122	preferences_value_length
123	remove_upload_file_permission
124	remove_manage_team_permission
125	remoteclusters_add_default_team_id
126	sharedchannels_remotes_add_deleteat
127	add_mfa_used_ts_to_users
128	create_scheduled_posts
129	add_property_system_architecture
135	sidebarchannels_categoryid
\.


--
-- Data for Name: db_migrations_calls; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.db_migrations_calls (version, name) FROM stdin;
1	create_calls_channels
2	create_calls
3	create_calls_sessions
4	create_calls_jobs
\.


--
-- Data for Name: desktoptokens; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.desktoptokens (token, createat, userid) FROM stdin;
\.


--
-- Data for Name: drafts; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.drafts (createat, updateat, deleteat, userid, channelid, rootid, message, props, fileids, priority) FROM stdin;
\.


--
-- Data for Name: emoji; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.emoji (id, createat, updateat, deleteat, creatorid, name) FROM stdin;
\.


--
-- Data for Name: fileinfo; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.fileinfo (id, creatorid, postid, createat, updateat, deleteat, path, thumbnailpath, previewpath, name, extension, size, mimetype, width, height, haspreviewimage, minipreview, content, remoteid, archived, channelid) FROM stdin;
\.


--
-- Data for Name: groupchannels; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.groupchannels (groupid, autoadd, schemeadmin, createat, deleteat, updateat, channelid) FROM stdin;
\.


--
-- Data for Name: groupmembers; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.groupmembers (groupid, userid, createat, deleteat) FROM stdin;
\.


--
-- Data for Name: groupteams; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.groupteams (groupid, autoadd, schemeadmin, createat, deleteat, updateat, teamid) FROM stdin;
\.


--
-- Data for Name: incomingwebhooks; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.incomingwebhooks (id, createat, updateat, deleteat, userid, channelid, teamid, displayname, description, username, iconurl, channellocked) FROM stdin;
\.


--
-- Data for Name: ir_category; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.ir_category (id, name, teamid, userid, collapsed, createat, updateat, deleteat) FROM stdin;
\.


--
-- Data for Name: ir_category_item; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.ir_category_item (type, categoryid, itemid) FROM stdin;
\.


--
-- Data for Name: ir_channelaction; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.ir_channelaction (id, channelid, enabled, deleteat, actiontype, triggertype, payload) FROM stdin;
\.


--
-- Data for Name: ir_incident; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.ir_incident (id, name, description, isactive, commanderuserid, teamid, channelid, createat, endat, deleteat, activestage, postid, playbookid, checklistsjson, activestagetitle, reminderpostid, broadcastchannelid, previousreminder, remindermessagetemplate, currentstatus, reporteruserid, concatenatedinviteduserids, defaultcommanderid, announcementchannelid, concatenatedwebhookoncreationurls, concatenatedinvitedgroupids, retrospective, messageonjoin, retrospectivepublishedat, retrospectivereminderintervalseconds, retrospectivewascanceled, concatenatedwebhookonstatusupdateurls, laststatusupdateat, exportchannelonfinishedenabled, categorizechannelenabled, categoryname, concatenatedbroadcastchannelids, channelidtorootid, remindertimerdefaultseconds, statusupdateenabled, retrospectiveenabled, statusupdatebroadcastchannelsenabled, statusupdatebroadcastwebhooksenabled, summarymodifiedat, createchannelmemberonnewparticipant, removechannelmemberonremovedparticipant, runtype) FROM stdin;
\.


--
-- Data for Name: ir_metric; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.ir_metric (incidentid, metricconfigid, value, published) FROM stdin;
\.


--
-- Data for Name: ir_metricconfig; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.ir_metricconfig (id, playbookid, title, description, type, target, ordering, deleteat) FROM stdin;
\.


--
-- Data for Name: ir_playbook; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.ir_playbook (id, title, description, teamid, createpublicincident, createat, deleteat, checklistsjson, numstages, numsteps, broadcastchannelid, remindermessagetemplate, remindertimerdefaultseconds, concatenatedinviteduserids, inviteusersenabled, defaultcommanderid, defaultcommanderenabled, announcementchannelid, announcementchannelenabled, concatenatedwebhookoncreationurls, webhookoncreationenabled, concatenatedinvitedgroupids, messageonjoin, messageonjoinenabled, retrospectivereminderintervalseconds, retrospectivetemplate, concatenatedwebhookonstatusupdateurls, webhookonstatusupdateenabled, concatenatedsignalanykeywords, signalanykeywordsenabled, updateat, exportchannelonfinishedenabled, categorizechannelenabled, categoryname, concatenatedbroadcastchannelids, broadcastenabled, runsummarytemplate, channelnametemplate, statusupdateenabled, retrospectiveenabled, public, runsummarytemplateenabled, createchannelmemberonnewparticipant, removechannelmemberonremovedparticipant, channelid, channelmode) FROM stdin;
\.


--
-- Data for Name: ir_playbookautofollow; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.ir_playbookautofollow (playbookid, userid) FROM stdin;
\.


--
-- Data for Name: ir_playbookmember; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.ir_playbookmember (playbookid, memberid, roles) FROM stdin;
\.


--
-- Data for Name: ir_run_participants; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.ir_run_participants (userid, incidentid, isfollower, isparticipant) FROM stdin;
\.


--
-- Data for Name: ir_statusposts; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.ir_statusposts (incidentid, postid) FROM stdin;
\.


--
-- Data for Name: ir_system; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.ir_system (skey, svalue) FROM stdin;
DatabaseVersion	0.63.0
\.


--
-- Data for Name: ir_timelineevent; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.ir_timelineevent (id, incidentid, createat, deleteat, eventat, eventtype, summary, details, postid, subjectuserid, creatoruserid) FROM stdin;
\.


--
-- Data for Name: ir_userinfo; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.ir_userinfo (id, lastdailytododmat, digestnotificationsettingsjson) FROM stdin;
\.


--
-- Data for Name: ir_viewedchannel; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.ir_viewedchannel (channelid, userid) FROM stdin;
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.jobs (id, type, priority, createat, startat, lastactivityat, status, progress, data) FROM stdin;
uauyy873db8ifezfx3pridwa7y	delete_dms_preferences_migration	0	1769537459045	1769537485816	1769537486834	success	100	{}
783ihr883t89urofbdinq847dh	delete_orphan_drafts_migration	0	1769537459044	1769537485816	1769537486842	success	100	{}
fcgo7hq88bngjroxuwhfui4gqy	delete_empty_drafts_migration	0	1769537459042	1769537485816	1769537486842	success	100	{}
e85ky49u5jbspbgzratdoxmsxa	migrations	0	1769537522865	1769537530828	1769537531283	success	0	{"last_done": "{\\"current_table\\":\\"ChannelMembers\\",\\"last_team_id\\":\\"urj86b44zineig6jtetjez8qww\\",\\"last_channel_id\\":\\"z4izaem3dif6i8h8imj3w8hmuy\\",\\"last_user\\":\\"q61z1nffcjbr9p1uf8zjyimqgr\\"}", "migration_key": "migration_advanced_permissions_phase_2"}
sukefzqemb85dytpqywzsn5tpo	expiry_notify	0	1771643438547	1771643443131	1771643443143	success	100	null
7jby64ec6f8g9kf1xd8kdstiay	expiry_notify	0	1771645811563	1771645816334	1771645816336	success	100	null
\.


--
-- Data for Name: licenses; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.licenses (id, createat, bytes) FROM stdin;
\.


--
-- Data for Name: linkmetadata; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.linkmetadata (hash, url, "timestamp", type, data) FROM stdin;
\.


--
-- Data for Name: llm_postmeta; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.llm_postmeta (rootpostid, title) FROM stdin;
\.


--
-- Data for Name: notifyadmin; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.notifyadmin (userid, createat, requiredplan, requiredfeature, trial, sentat) FROM stdin;
\.


--
-- Data for Name: oauthaccessdata; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.oauthaccessdata (token, refreshtoken, redirecturi, clientid, userid, expiresat, scope) FROM stdin;
\.


--
-- Data for Name: oauthapps; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.oauthapps (id, creatorid, createat, updateat, clientsecret, name, description, callbackurls, homepage, istrusted, iconurl, mattermostappid) FROM stdin;
\.


--
-- Data for Name: oauthauthdata; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.oauthauthdata (clientid, userid, code, expiresin, createat, redirecturi, state, scope) FROM stdin;
\.


--
-- Data for Name: outgoingoauthconnections; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.outgoingoauthconnections (id, name, creatorid, createat, updateat, clientid, clientsecret, credentialsusername, credentialspassword, oauthtokenurl, granttype, audiences) FROM stdin;
\.


--
-- Data for Name: outgoingwebhooks; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.outgoingwebhooks (id, token, createat, updateat, deleteat, creatorid, channelid, teamid, triggerwords, callbackurls, displayname, contenttype, triggerwhen, username, iconurl, description) FROM stdin;
\.


--
-- Data for Name: persistentnotifications; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.persistentnotifications (postid, createat, lastsentat, deleteat, sentcount) FROM stdin;
\.


--
-- Data for Name: pluginkeyvaluestore; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.pluginkeyvaluestore (pluginid, pkey, pvalue, expireat) FROM stdin;
playbooks	mmi_botid	\\x6f69396a687466737770627462666f74707375756a37317a7563	0
com.mattermost.nps	ServerUpgrade-10.5.0	\\x7b227365727665725f76657273696f6e223a2231302e352e30222c22757067726164655f6174223a22323032362d30312d32375431383a31313a30322e3536393331313833365a227d	0
com.mattermost.nps	WelcomeFeedbackMigration	\\x7b224372656174654174223a22323032362d30312d32375431383a31313a30322e3536393331313833365a227d	0
com.mattermost.nps	Survey-10.5.0	\\x7b227365727665725f76657273696f6e223a2231302e352e30222c226372656174655f6174223a22323032362d30312d32375431383a31313a30322e3536393331313833365a222c2273746172745f6174223a22323032362d30332d31335431383a31313a30322e3536393331313833365a227d	0
com.mattermost.nps	LastAdminNotice	\\x22323032362d30312d32375431383a31313a30322e3536393331313833365a22	0
mattermost-ai	migrate_services_to_bots_done	\\x74727565	0
com.mattermost.calls	mmi_botid	\\x696a3377697572336b6962386d6e77666d776574787179727a72	0
\.


--
-- Data for Name: postacknowledgements; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.postacknowledgements (postid, userid, acknowledgedat) FROM stdin;
\.


--
-- Data for Name: postreminders; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.postreminders (postid, userid, targettime) FROM stdin;
\.


--
-- Data for Name: posts; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.posts (id, createat, updateat, deleteat, userid, channelid, rootid, originalid, message, type, props, hashtags, filenames, fileids, hasreactions, editat, ispinned, remoteid) FROM stdin;
hjjrp6yjejgeje4cjtxz5q6n9y	1769537496271	1769537496271	0	ctz5686fy7fe5r3kfp8ckhp5yw	rz5riz8jkfru8ki13145gsq3fo			admin joined the team.	system_join_team	{"username": "admin"}		[]	[]	f	0	f	\N
59i96qb1wbgrxekbnumg5zbber	1769537496309	1769537496309	0	ctz5686fy7fe5r3kfp8ckhp5yw	z4izaem3dif6i8h8imj3w8hmuy			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
7sit7763jbfstn7irfc4cm6fty	1769537498272	1769537498272	0	arf1sprce7nq3qnjh1hsac91nw	rz5riz8jkfru8ki13145gsq3fo			alice joined the team.	system_join_team	{"username": "alice"}		[]	[]	f	0	f	\N
ipzyegmb3py37kajpfnnrtxuxh	1769537498278	1769537498278	0	arf1sprce7nq3qnjh1hsac91nw	z4izaem3dif6i8h8imj3w8hmuy			alice joined the channel.	system_join_channel	{"username": "alice"}		[]	[]	f	0	f	\N
77f8qciwsfd18ycpuaowuhct7e	1769537498635	1769537498635	0	arf1sprce7nq3qnjh1hsac91nw	skboo5k3cfg4zqm8yb6m33rn9a			alice joined the team.	system_join_team	{"username": "alice"}		[]	[]	f	0	f	\N
ik1ahahsa78e8ddhfgq33i6wsc	1769537498643	1769537498643	0	arf1sprce7nq3qnjh1hsac91nw	wxt9f3xwg7gfmpuau7pugetm1o			alice joined the channel.	system_join_channel	{"username": "alice"}		[]	[]	f	0	f	\N
c68hsgihgj8juqn8xdcex89s5a	1769537500567	1769537500567	0	gud7udwfobn3pnu8x81ef7rxna	rz5riz8jkfru8ki13145gsq3fo			bob joined the team.	system_join_team	{"username": "bob"}		[]	[]	f	0	f	\N
za3t1k7e8tghpfum4no16e55zc	1769537500573	1769537500573	0	gud7udwfobn3pnu8x81ef7rxna	z4izaem3dif6i8h8imj3w8hmuy			bob joined the channel.	system_join_channel	{"username": "bob"}		[]	[]	f	0	f	\N
gxzaprei7pgz7xpmnmuyd5bm8r	1769537502456	1769537502456	0	6zwwofjeipryzeon9xpnuq84xy	rz5riz8jkfru8ki13145gsq3fo			charlie joined the team.	system_join_team	{"username": "charlie"}		[]	[]	f	0	f	\N
9gwkmkqgrpy79qfowg34rcyiza	1769537502461	1769537502461	0	6zwwofjeipryzeon9xpnuq84xy	z4izaem3dif6i8h8imj3w8hmuy			charlie joined the channel.	system_join_channel	{"username": "charlie"}		[]	[]	f	0	f	\N
pt51bsmx6bgbdjjmjmafc76kwc	1769537504314	1769537504314	0	jueqmzyedbruppmb8u956ykphe	rz5riz8jkfru8ki13145gsq3fo			diana joined the team.	system_join_team	{"username": "diana"}		[]	[]	f	0	f	\N
hzrubhu9gtng9mtx6u174d8ysw	1769537504321	1769537504321	0	jueqmzyedbruppmb8u956ykphe	z4izaem3dif6i8h8imj3w8hmuy			diana joined the channel.	system_join_channel	{"username": "diana"}		[]	[]	f	0	f	\N
yp1dfg3b1jf6dxo5unhmpgy7de	1769537506147	1769537506147	0	ba1chd3qnprj5jx1tw6goqy4iy	rz5riz8jkfru8ki13145gsq3fo			eve joined the team.	system_join_team	{"username": "eve"}		[]	[]	f	0	f	\N
hksjhi9o4bfetxsztgrb96mcic	1769537506152	1769537506152	0	ba1chd3qnprj5jx1tw6goqy4iy	z4izaem3dif6i8h8imj3w8hmuy			eve joined the channel.	system_join_channel	{"username": "eve"}		[]	[]	f	0	f	\N
aa9tf8caft837myun88x1nhnyh	1769537506509	1769537506509	0	ba1chd3qnprj5jx1tw6goqy4iy	skboo5k3cfg4zqm8yb6m33rn9a			eve joined the team.	system_join_team	{"username": "eve"}		[]	[]	f	0	f	\N
w46omz87pirg8ros6cradrxjsy	1769537506516	1769537506516	0	ba1chd3qnprj5jx1tw6goqy4iy	wxt9f3xwg7gfmpuau7pugetm1o			eve joined the channel.	system_join_channel	{"username": "eve"}		[]	[]	f	0	f	\N
88o7yqkoyprqu83xp3f1ugnomw	1769537508326	1769537508326	0	j4i1gcm7stni8cqyhqixaexejw	rz5riz8jkfru8ki13145gsq3fo			frank joined the team.	system_join_team	{"username": "frank"}		[]	[]	f	0	f	\N
9ttq43d8i3ysiqa7cuzzs3ck7c	1769537508332	1769537508332	0	j4i1gcm7stni8cqyhqixaexejw	z4izaem3dif6i8h8imj3w8hmuy			frank joined the channel.	system_join_channel	{"username": "frank"}		[]	[]	f	0	f	\N
44zne8f5kfy9tpmgz6ur3jtgqr	1769537508660	1769537508660	0	j4i1gcm7stni8cqyhqixaexejw	skboo5k3cfg4zqm8yb6m33rn9a			frank joined the team.	system_join_team	{"username": "frank"}		[]	[]	f	0	f	\N
4bpnufgm6f8f9qusxfasrxncpa	1769537508666	1769537508666	0	j4i1gcm7stni8cqyhqixaexejw	wxt9f3xwg7gfmpuau7pugetm1o			frank joined the channel.	system_join_channel	{"username": "frank"}		[]	[]	f	0	f	\N
a4qmokozitgimkbfat11kcgute	1769537510552	1769537510552	0	7kzaisytntgidxic4jfr1yrg3y	rz5riz8jkfru8ki13145gsq3fo			grace joined the team.	system_join_team	{"username": "grace"}		[]	[]	f	0	f	\N
jdnpi4dwe7yetmog83pbd5wqky	1769537510562	1769537510562	0	7kzaisytntgidxic4jfr1yrg3y	z4izaem3dif6i8h8imj3w8hmuy			grace joined the channel.	system_join_channel	{"username": "grace"}		[]	[]	f	0	f	\N
hoipmb6twi8a5k17q55zj4s38w	1769537510973	1769537510973	0	7kzaisytntgidxic4jfr1yrg3y	skboo5k3cfg4zqm8yb6m33rn9a			grace joined the team.	system_join_team	{"username": "grace"}		[]	[]	f	0	f	\N
pinx5esz67djpqp4a94rwp37ga	1769537510989	1769537510989	0	7kzaisytntgidxic4jfr1yrg3y	wxt9f3xwg7gfmpuau7pugetm1o			grace joined the channel.	system_join_channel	{"username": "grace"}		[]	[]	f	0	f	\N
azyoi48qiiyctf5c3btfmo4j4e	1769537512874	1769537512874	0	4d5pwx1uob8gdmgqmc3fs9hfpe	rz5riz8jkfru8ki13145gsq3fo			demo joined the team.	system_join_team	{"username": "demo"}		[]	[]	f	0	f	\N
5sda64pfobrsujtm398gjdpnrr	1769537512879	1769537512879	0	4d5pwx1uob8gdmgqmc3fs9hfpe	z4izaem3dif6i8h8imj3w8hmuy			demo joined the channel.	system_join_channel	{"username": "demo"}		[]	[]	f	0	f	\N
8b1nk18u9ifcmkj6f4sdx73bre	1769537514775	1769537514775	0	3a17zh894jrgbpw9ixhpjsyc9h	rz5riz8jkfru8ki13145gsq3fo			user1 joined the team.	system_join_team	{"username": "user1"}		[]	[]	f	0	f	\N
mtdsejrpr3dntqmswywukafpkr	1769537514784	1769537514784	0	3a17zh894jrgbpw9ixhpjsyc9h	z4izaem3dif6i8h8imj3w8hmuy			user1 joined the channel.	system_join_channel	{"username": "user1"}		[]	[]	f	0	f	\N
whus8o8xqjgqxy4ounzo8cdioa	1769537516615	1769537516615	0	eeif4rm7q3rrig6u1qkcusw35h	rz5riz8jkfru8ki13145gsq3fo			alex.chen joined the team.	system_join_team	{"username": "alex.chen"}		[]	[]	f	0	f	\N
8yqw67q6zjdudpim4kzqhrcquc	1769537516621	1769537516621	0	eeif4rm7q3rrig6u1qkcusw35h	z4izaem3dif6i8h8imj3w8hmuy			alex.chen joined the channel.	system_join_channel	{"username": "alex.chen"}		[]	[]	f	0	f	\N
hzgh1hyru3dembmfz9eftpgdba	1769537516962	1769537516962	0	eeif4rm7q3rrig6u1qkcusw35h	skboo5k3cfg4zqm8yb6m33rn9a			alex.chen joined the team.	system_join_team	{"username": "alex.chen"}		[]	[]	f	0	f	\N
mti9uhwp57yjzpg8n6qeucahfe	1769537516968	1769537516968	0	eeif4rm7q3rrig6u1qkcusw35h	wxt9f3xwg7gfmpuau7pugetm1o			alex.chen joined the channel.	system_join_channel	{"username": "alex.chen"}		[]	[]	f	0	f	\N
tnj7djnqyjbsjgrk77okh45fpa	1769537518778	1769537518778	0	q61z1nffcjbr9p1uf8zjyimqgr	rz5riz8jkfru8ki13145gsq3fo			blake.sullivan joined the team.	system_join_team	{"username": "blake.sullivan"}		[]	[]	f	0	f	\N
nxff7mrjetf1bpuib6ua9dyi1c	1769537518783	1769537518783	0	q61z1nffcjbr9p1uf8zjyimqgr	z4izaem3dif6i8h8imj3w8hmuy			blake.sullivan joined the channel.	system_join_channel	{"username": "blake.sullivan"}		[]	[]	f	0	f	\N
835n6gh9gi8muyc86wkhobizzy	1769537519122	1769537519122	0	q61z1nffcjbr9p1uf8zjyimqgr	skboo5k3cfg4zqm8yb6m33rn9a			blake.sullivan joined the team.	system_join_team	{"username": "blake.sullivan"}		[]	[]	f	0	f	\N
rg9roeiuxbrcdbp7w1cyr4puja	1769537519127	1769537519127	0	q61z1nffcjbr9p1uf8zjyimqgr	wxt9f3xwg7gfmpuau7pugetm1o			blake.sullivan joined the channel.	system_join_channel	{"username": "blake.sullivan"}		[]	[]	f	0	f	\N
zokedi1ukifp9q1zxuyjbpsyec	1769537521013	1769537521013	0	dr6nhfmd4iyp5dhfkkd1b1fy1h	rz5riz8jkfru8ki13145gsq3fo			mallory joined the team.	system_join_team	{"username": "mallory"}		[]	[]	f	0	f	\N
q97pzbph37g88m3nckw4m53eja	1769537521020	1769537521020	0	dr6nhfmd4iyp5dhfkkd1b1fy1h	z4izaem3dif6i8h8imj3w8hmuy			mallory joined the channel.	system_join_channel	{"username": "mallory"}		[]	[]	f	0	f	\N
5a1gqk9gpfb13ytxmiunpo453r	1769537527868	1769537527868	0	1w1w87fzdin5fpdta4ra8h5opw	rz5riz8jkfru8ki13145gsq3fo			analytics_user joined the team.	system_join_team	{"username": "analytics_user"}		[]	[]	f	0	f	\N
tabyouhydjfq9mqw81a1ra5h8c	1769537527875	1769537527875	0	1w1w87fzdin5fpdta4ra8h5opw	z4izaem3dif6i8h8imj3w8hmuy			analytics_user joined the channel.	system_join_channel	{"username": "analytics_user"}		[]	[]	f	0	f	\N
\.


--
-- Data for Name: postspriority; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.postspriority (postid, channelid, priority, requestedack, persistentnotifications) FROM stdin;
\.


--
-- Data for Name: preferences; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.preferences (userid, category, name, value) FROM stdin;
ctz5686fy7fe5r3kfp8ckhp5yw	recommended_next_steps	hide	false
ctz5686fy7fe5r3kfp8ckhp5yw	tutorial_step	ctz5686fy7fe5r3kfp8ckhp5yw	0
ctz5686fy7fe5r3kfp8ckhp5yw	system_notice	GMasDM	true
arf1sprce7nq3qnjh1hsac91nw	recommended_next_steps	hide	false
arf1sprce7nq3qnjh1hsac91nw	tutorial_step	arf1sprce7nq3qnjh1hsac91nw	0
arf1sprce7nq3qnjh1hsac91nw	system_notice	GMasDM	true
gud7udwfobn3pnu8x81ef7rxna	recommended_next_steps	hide	false
gud7udwfobn3pnu8x81ef7rxna	tutorial_step	gud7udwfobn3pnu8x81ef7rxna	0
gud7udwfobn3pnu8x81ef7rxna	system_notice	GMasDM	true
6zwwofjeipryzeon9xpnuq84xy	recommended_next_steps	hide	false
6zwwofjeipryzeon9xpnuq84xy	tutorial_step	6zwwofjeipryzeon9xpnuq84xy	0
6zwwofjeipryzeon9xpnuq84xy	system_notice	GMasDM	true
jueqmzyedbruppmb8u956ykphe	recommended_next_steps	hide	false
jueqmzyedbruppmb8u956ykphe	tutorial_step	jueqmzyedbruppmb8u956ykphe	0
jueqmzyedbruppmb8u956ykphe	system_notice	GMasDM	true
ba1chd3qnprj5jx1tw6goqy4iy	recommended_next_steps	hide	false
ba1chd3qnprj5jx1tw6goqy4iy	tutorial_step	ba1chd3qnprj5jx1tw6goqy4iy	0
ba1chd3qnprj5jx1tw6goqy4iy	system_notice	GMasDM	true
j4i1gcm7stni8cqyhqixaexejw	recommended_next_steps	hide	false
j4i1gcm7stni8cqyhqixaexejw	tutorial_step	j4i1gcm7stni8cqyhqixaexejw	0
j4i1gcm7stni8cqyhqixaexejw	system_notice	GMasDM	true
7kzaisytntgidxic4jfr1yrg3y	recommended_next_steps	hide	false
7kzaisytntgidxic4jfr1yrg3y	tutorial_step	7kzaisytntgidxic4jfr1yrg3y	0
7kzaisytntgidxic4jfr1yrg3y	system_notice	GMasDM	true
4d5pwx1uob8gdmgqmc3fs9hfpe	recommended_next_steps	hide	false
4d5pwx1uob8gdmgqmc3fs9hfpe	tutorial_step	4d5pwx1uob8gdmgqmc3fs9hfpe	0
4d5pwx1uob8gdmgqmc3fs9hfpe	system_notice	GMasDM	true
3a17zh894jrgbpw9ixhpjsyc9h	recommended_next_steps	hide	false
3a17zh894jrgbpw9ixhpjsyc9h	tutorial_step	3a17zh894jrgbpw9ixhpjsyc9h	0
3a17zh894jrgbpw9ixhpjsyc9h	system_notice	GMasDM	true
eeif4rm7q3rrig6u1qkcusw35h	recommended_next_steps	hide	false
eeif4rm7q3rrig6u1qkcusw35h	tutorial_step	eeif4rm7q3rrig6u1qkcusw35h	0
eeif4rm7q3rrig6u1qkcusw35h	system_notice	GMasDM	true
q61z1nffcjbr9p1uf8zjyimqgr	recommended_next_steps	hide	false
q61z1nffcjbr9p1uf8zjyimqgr	tutorial_step	q61z1nffcjbr9p1uf8zjyimqgr	0
q61z1nffcjbr9p1uf8zjyimqgr	system_notice	GMasDM	true
dr6nhfmd4iyp5dhfkkd1b1fy1h	recommended_next_steps	hide	false
dr6nhfmd4iyp5dhfkkd1b1fy1h	tutorial_step	dr6nhfmd4iyp5dhfkkd1b1fy1h	0
dr6nhfmd4iyp5dhfkkd1b1fy1h	system_notice	GMasDM	true
1w1w87fzdin5fpdta4ra8h5opw	recommended_next_steps	hide	false
1w1w87fzdin5fpdta4ra8h5opw	tutorial_step	1w1w87fzdin5fpdta4ra8h5opw	0
1w1w87fzdin5fpdta4ra8h5opw	system_notice	GMasDM	true
\.


--
-- Data for Name: productnoticeviewstate; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.productnoticeviewstate (userid, noticeid, viewed, "timestamp") FROM stdin;
\.


--
-- Data for Name: propertyfields; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.propertyfields (id, groupid, name, type, attrs, targetid, targettype, createat, updateat, deleteat) FROM stdin;
\.


--
-- Data for Name: propertygroups; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.propertygroups (id, name) FROM stdin;
\.


--
-- Data for Name: propertyvalues; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.propertyvalues (id, targetid, targettype, groupid, fieldid, value, createat, updateat, deleteat) FROM stdin;
\.


--
-- Data for Name: publicchannels; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.publicchannels (id, deleteat, teamid, displayname, name, header, purpose) FROM stdin;
rz5riz8jkfru8ki13145gsq3fo	0	urj86b44zineig6jtetjez8qww	Town Square	town-square		
z4izaem3dif6i8h8imj3w8hmuy	0	urj86b44zineig6jtetjez8qww	Off-Topic	off-topic		
skboo5k3cfg4zqm8yb6m33rn9a	0	nehyf6um5pfg7ejqkk4ccumroc	Town Square	town-square		
wxt9f3xwg7gfmpuau7pugetm1o	0	nehyf6um5pfg7ejqkk4ccumroc	Off-Topic	off-topic		
\.


--
-- Data for Name: reactions; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.reactions (userid, postid, emojiname, createat, updateat, deleteat, remoteid, channelid) FROM stdin;
\.


--
-- Data for Name: recentsearches; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.recentsearches (userid, searchpointer, query, createat) FROM stdin;
\.


--
-- Data for Name: remoteclusters; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.remoteclusters (remoteid, remoteteamid, name, displayname, siteurl, createat, lastpingat, token, remotetoken, topics, creatorid, pluginid, options, defaultteamid, deleteat) FROM stdin;
\.


--
-- Data for Name: retentionidsfordeletion; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.retentionidsfordeletion (id, tablename, ids) FROM stdin;
\.


--
-- Data for Name: retentionpolicies; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.retentionpolicies (id, displayname, postduration) FROM stdin;
\.


--
-- Data for Name: retentionpolicieschannels; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.retentionpolicieschannels (policyid, channelid) FROM stdin;
\.


--
-- Data for Name: retentionpoliciesteams; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.retentionpoliciesteams (policyid, teamid) FROM stdin;
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.roles (id, name, displayname, description, createat, updateat, deleteat, permissions, schememanaged, builtin) FROM stdin;
ycs5p3gpepbdx8p4sqqjh1ejcc	channel_guest	authentication.roles.channel_guest.name	authentication.roles.channel_guest.description	1769537458641	1769537459028	0	 read_channel_content remove_reaction edit_post create_post use_channel_mentions add_reaction upload_file read_channel	t	t
q8p15b3zqfbyicdg6e1rkabxbr	channel_user	authentication.roles.channel_user.name	authentication.roles.channel_user.description	1769537458642	1769537459028	0	 remove_reaction manage_public_channel_properties use_channel_mentions read_private_channel_groups delete_post manage_public_channel_members manage_private_channel_properties add_reaction read_channel_content read_public_channel_groups add_bookmark_private_channel delete_bookmark_private_channel delete_public_channel edit_post use_group_mentions add_bookmark_public_channel delete_bookmark_public_channel manage_private_channel_members delete_private_channel order_bookmark_public_channel edit_bookmark_private_channel get_public_link create_post upload_file edit_bookmark_public_channel read_channel order_bookmark_private_channel	t	t
qmfgttc73j8r9j4dnnukbkbfkr	team_guest	authentication.roles.team_guest.name	authentication.roles.team_guest.description	1769537458643	1769537459028	0	 view_team	t	t
rgumhyxjpfyuby5s5679j5r8wr	playbook_member	authentication.roles.playbook_member.name	authentication.roles.playbook_member.description	1769537458643	1769537459029	0	 playbook_public_manage_members playbook_public_manage_properties playbook_private_view playbook_private_manage_members playbook_private_manage_properties run_create playbook_public_view	t	t
zt8pt31ap78w7euwt9583pau8r	system_guest	authentication.roles.global_guest.name	authentication.roles.global_guest.description	1769537458644	1769537459029	0	 create_group_channel create_direct_channel	t	t
idaropz7gtgejkyhsd7dt3soaw	system_post_all_public	authentication.roles.system_post_all_public.name	authentication.roles.system_post_all_public.description	1769537458644	1769537459029	0	 use_channel_mentions create_post_public use_group_mentions	f	t
u55wp9m1sffadcjywt3ar8ie7r	team_post_all	authentication.roles.team_post_all.name	authentication.roles.team_post_all.description	1769537458626	1769537459026	0	 use_group_mentions create_post upload_file use_channel_mentions	f	t
camrmjrg8idp9m1upbg1scowyy	team_post_all_public	authentication.roles.team_post_all_public.name	authentication.roles.team_post_all_public.description	1769537458628	1769537459026	0	 use_channel_mentions create_post_public use_group_mentions	f	t
ueegw7adbpdgtnt7bnmuxhqg3w	channel_admin	authentication.roles.channel_admin.name	authentication.roles.channel_admin.description	1769537458635	1769537459027	0	 delete_bookmark_public_channel use_channel_mentions delete_bookmark_private_channel edit_bookmark_public_channel add_bookmark_private_channel edit_bookmark_private_channel order_bookmark_private_channel manage_channel_roles read_private_channel_groups add_bookmark_public_channel upload_file add_reaction use_group_mentions read_public_channel_groups order_bookmark_public_channel manage_private_channel_members create_post manage_public_channel_members remove_reaction	t	t
8rnjc4fdntrh9fafdt6gqsckhe	team_user	authentication.roles.team_user.name	authentication.roles.team_user.description	1769537458636	1769537459027	0	 view_team create_public_channel add_user_to_team playbook_private_create create_private_channel join_public_channels read_public_channel playbook_public_create invite_user list_team_channels	t	t
r74orqt973nwdjzxtbrcs1qrua	system_post_all	authentication.roles.system_post_all.name	authentication.roles.system_post_all.description	1769537458637	1769537459027	0	 use_channel_mentions upload_file create_post use_group_mentions	f	t
kccddxrnejn15g9jbi3mssadgr	custom_group_user	authentication.roles.custom_group_user.name	authentication.roles.custom_group_user.description	1769537458640	1769537459028	0		f	f
wekrxcr5u78rzytmpo6ht6dwec	team_admin	authentication.roles.team_admin.name	authentication.roles.team_admin.description	1769537458645	1769537459029	0	 manage_others_outgoing_webhooks upload_file add_bookmark_private_channel manage_outgoing_webhooks add_reaction add_bookmark_public_channel playbook_public_manage_roles use_channel_mentions delete_bookmark_public_channel order_bookmark_public_channel remove_user_from_team read_private_channel_groups remove_reaction manage_team_roles edit_bookmark_private_channel read_public_channel_groups convert_public_channel_to_private delete_post manage_slash_commands manage_channel_roles manage_team manage_others_incoming_webhooks delete_bookmark_private_channel delete_others_posts manage_incoming_webhooks use_group_mentions edit_bookmark_public_channel import_team manage_private_channel_members convert_private_channel_to_public create_post playbook_private_manage_roles manage_public_channel_members order_bookmark_private_channel manage_others_slash_commands	t	t
cmbc5kq5h7n99p1qrr881uzcsy	system_read_only_admin	authentication.roles.system_read_only_admin.name	authentication.roles.system_read_only_admin.description	1769537458633	1769537459027	0	 test_ldap sysconsole_read_experimental_features sysconsole_read_site_notices sysconsole_read_user_management_groups get_logs sysconsole_read_environment_image_proxy sysconsole_read_integrations_bot_accounts sysconsole_read_site_users_and_teams sysconsole_read_experimental_feature_flags sysconsole_read_integrations_cors read_license_information read_compliance_export_job read_public_channel sysconsole_read_about_edition_and_license sysconsole_read_environment_smtp sysconsole_read_site_public_links sysconsole_read_site_localization sysconsole_read_site_file_sharing_and_downloads read_ldap_sync_job sysconsole_read_integrations_gif list_public_teams sysconsole_read_authentication_password sysconsole_read_authentication_openid sysconsole_read_environment_logging sysconsole_read_environment_database read_elasticsearch_post_indexing_job sysconsole_read_site_emoji sysconsole_read_site_notifications sysconsole_read_reporting_site_statistics read_data_retention_job get_analytics sysconsole_read_integrations_integration_management sysconsole_read_compliance_custom_terms_of_service sysconsole_read_environment_performance_monitoring sysconsole_read_compliance_compliance_monitoring sysconsole_read_experimental_bleve sysconsole_read_authentication_saml sysconsole_read_authentication_guest_access sysconsole_read_authentication_signup sysconsole_read_site_customization sysconsole_read_user_management_channels sysconsole_read_environment_high_availability sysconsole_read_authentication_ldap sysconsole_read_environment_rate_limiting sysconsole_read_products_boards sysconsole_read_environment_developer sysconsole_read_compliance_data_retention_policy sysconsole_read_environment_file_storage sysconsole_read_authentication_mfa sysconsole_read_reporting_server_logs sysconsole_read_user_management_permissions sysconsole_read_reporting_team_statistics read_elasticsearch_post_aggregation_job list_private_teams sysconsole_read_environment_elasticsearch sysconsole_read_environment_web_server sysconsole_read_site_posts sysconsole_read_environment_session_lengths download_compliance_export_result sysconsole_read_compliance_compliance_export read_channel sysconsole_read_user_management_users read_audits read_public_channel_groups view_team sysconsole_read_environment_push_notification_server sysconsole_read_site_announcement_banner sysconsole_read_plugins read_other_users_teams sysconsole_read_authentication_email sysconsole_read_user_management_teams read_private_channel_groups	f	t
kjhpoicfd3gj3dzwgjfj1fc6ca	playbook_admin	authentication.roles.playbook_admin.name	authentication.roles.playbook_admin.description	1769537458647	1769537459030	0	 playbook_private_manage_roles playbook_private_manage_properties playbook_public_make_private playbook_public_manage_members playbook_public_manage_roles playbook_public_manage_properties playbook_private_manage_members	t	t
jhqebijkb7gn7fxfo1thhkj4te	run_admin	authentication.roles.run_admin.name	authentication.roles.run_admin.description	1769537458648	1769537459030	0	 run_manage_members run_manage_properties	t	t
3ds73crwdbgiik8fqzqqfnkemh	run_member	authentication.roles.run_member.name	authentication.roles.run_member.description	1769537458649	1769537459030	0	 run_view	t	t
ek8w3q6i7bg5tkej9zxm7rzmmr	system_user_access_token	authentication.roles.system_user_access_token.name	authentication.roles.system_user_access_token.description	1769537458649	1769537459030	0	 revoke_user_access_token create_user_access_token read_user_access_token	f	t
ytechdgk9ffnxfyjw4s65gz8jw	system_custom_group_admin	authentication.roles.system_custom_group_admin.name	authentication.roles.system_custom_group_admin.description	1769537458649	1769537459030	0	 edit_custom_group delete_custom_group restore_custom_group manage_custom_group_members create_custom_group	f	t
7gzfkxudnjnq5r1xm19g5f6s6w	system_user	authentication.roles.global_user.name	authentication.roles.global_user.description	1769537458629	1769537459031	0	 restore_custom_group delete_emojis create_emojis create_group_channel view_members create_custom_group edit_custom_group manage_custom_group_members create_direct_channel delete_custom_group join_public_teams list_public_teams create_team	t	t
c85axqg47jgntdumrts4e6w1uh	system_admin	authentication.roles.global_admin.name	authentication.roles.global_admin.description	1769537458651	1769537459031	0	 run_view playbook_private_make_public sysconsole_write_integrations_cors manage_elasticsearch_post_aggregation_job sysconsole_write_reporting_team_statistics view_members read_other_users_teams sysconsole_write_environment_database read_deleted_posts delete_emojis manage_public_channel_properties read_channel sysconsole_read_integrations_gif sysconsole_write_user_management_channels edit_bookmark_private_channel sysconsole_read_environment_developer sysconsole_read_authentication_mfa create_ldap_sync_job delete_others_emojis manage_license_information create_public_channel sysconsole_read_authentication_guest_access sysconsole_read_site_ip_filters sysconsole_read_compliance_custom_terms_of_service sysconsole_write_billing sysconsole_write_reporting_site_statistics manage_jobs sysconsole_write_environment_push_notification_server sysconsole_read_site_emoji sysconsole_write_site_customization sysconsole_write_experimental_features sysconsole_write_site_notices manage_post_bleve_indexes_job sysconsole_read_reporting_site_statistics sysconsole_write_site_file_sharing_and_downloads test_site_url list_users_without_team sysconsole_write_environment_developer join_private_teams sysconsole_read_user_management_groups sysconsole_write_site_announcement_banner edit_others_posts playbook_public_make_private sysconsole_write_environment_high_availability sysconsole_read_compliance_compliance_monitoring sysconsole_read_environment_file_storage manage_channel_roles import_team sysconsole_write_site_emoji create_compliance_export_job get_analytics sysconsole_write_experimental_bleve playbook_public_manage_members sysconsole_write_about_edition_and_license manage_team_roles sysconsole_write_authentication_ldap sysconsole_read_user_management_permissions remove_ldap_private_cert list_private_teams sysconsole_read_site_users_and_teams demote_to_guest read_compliance_export_job create_elasticsearch_post_aggregation_job create_group_channel remove_saml_private_cert sysconsole_write_user_management_teams read_channel_content playbook_private_manage_properties manage_others_bots sysconsole_write_environment_rate_limiting playbook_private_manage_members view_team sysconsole_read_reporting_server_logs sysconsole_read_authentication_email recycle_database_connections playbook_private_view sysconsole_read_environment_performance_monitoring create_elasticsearch_post_indexing_job sysconsole_write_environment_session_lengths create_team promote_guest playbook_private_create sysconsole_read_user_management_system_roles join_public_channels delete_custom_group delete_bookmark_public_channel sysconsole_read_products_boards playbook_private_manage_roles reload_config read_bots playbook_public_manage_roles manage_compliance_export_job manage_elasticsearch_post_indexing_job revoke_user_access_token assign_system_admin_role create_bot manage_outgoing_oauth_connections add_saml_idp_cert add_bookmark_private_channel sysconsole_write_environment_performance_monitoring sysconsole_write_user_management_permissions add_saml_public_cert sysconsole_read_billing sysconsole_write_reporting_server_logs sysconsole_read_site_announcement_banner remove_others_reactions sysconsole_read_compliance_compliance_export edit_post sysconsole_read_environment_push_notification_server sysconsole_read_reporting_team_statistics add_saml_private_cert sysconsole_read_experimental_feature_flags invalidate_caches read_public_channel test_email manage_shared_channels sysconsole_read_user_management_teams sysconsole_write_products_boards manage_others_outgoing_webhooks run_manage_members create_post_public sysconsole_read_about_edition_and_license sysconsole_read_authentication_signup edit_custom_group manage_others_incoming_webhooks sysconsole_write_authentication_signup test_s3 manage_public_channel_members remove_reaction get_saml_cert_status sysconsole_read_authentication_saml sysconsole_write_integrations_bot_accounts delete_private_channel manage_outgoing_webhooks add_user_to_team read_data_retention_job manage_incoming_webhooks sysconsole_read_environment_database playbook_public_view download_compliance_export_result add_reaction run_manage_properties restore_custom_group sysconsole_read_environment_session_lengths sysconsole_write_authentication_password convert_private_channel_to_public manage_slash_commands sysconsole_read_site_posts sysconsole_read_environment_elasticsearch manage_bots read_license_information sysconsole_read_environment_high_availability sysconsole_read_environment_web_server sysconsole_read_environment_image_proxy manage_system_wide_oauth get_saml_metadata_from_idp manage_roles create_post_bleve_indexes_job manage_private_channel_members sysconsole_write_user_management_users sysconsole_read_site_file_sharing_and_downloads list_public_teams read_elasticsearch_post_indexing_job manage_ldap_sync_job invite_user sysconsole_write_environment_file_storage sysconsole_read_site_notifications create_direct_channel remove_user_from_team read_audits delete_public_channel run_create test_ldap sysconsole_write_environment_smtp add_ldap_private_cert manage_data_retention_job sysconsole_write_authentication_mfa manage_system sysconsole_read_user_management_users invalidate_email_invite invite_guest sysconsole_read_experimental_bleve manage_secure_connections sysconsole_read_environment_logging remove_ldap_public_cert read_user_access_token sysconsole_write_compliance_compliance_monitoring sysconsole_write_integrations_integration_management convert_public_channel_to_private sysconsole_write_plugins read_elasticsearch_post_aggregation_job manage_team create_post_ephemeral edit_other_users create_data_retention_job sysconsole_write_compliance_custom_terms_of_service sysconsole_write_integrations_gif create_user_access_token add_bookmark_public_channel playbook_public_create delete_bookmark_private_channel sysconsole_read_environment_rate_limiting purge_bleve_indexes manage_others_slash_commands read_others_bots sysconsole_read_integrations_integration_management sysconsole_write_experimental_feature_flags sysconsole_write_compliance_data_retention_policy sysconsole_write_site_users_and_teams sysconsole_write_site_public_links sysconsole_write_authentication_email delete_post use_channel_mentions assign_bot read_public_channel_groups sysconsole_write_environment_elasticsearch sysconsole_write_site_localization use_group_mentions sysconsole_write_authentication_openid create_private_channel sysconsole_read_site_customization sysconsole_read_integrations_cors delete_others_posts edit_bookmark_public_channel test_elasticsearch sysconsole_read_user_management_channels order_bookmark_private_channel sysconsole_read_authentication_ldap get_logs read_ldap_sync_job create_post sysconsole_write_authentication_saml sysconsole_write_environment_logging sysconsole_write_compliance_compliance_export manage_private_channel_properties sysconsole_read_site_notices sysconsole_write_user_management_groups sysconsole_read_site_localization create_custom_group remove_saml_idp_cert sysconsole_write_environment_image_proxy sysconsole_read_plugins create_emojis sysconsole_write_site_posts purge_elasticsearch_indexes remove_saml_public_cert sysconsole_write_environment_web_server get_public_link sysconsole_read_authentication_password read_private_channel_groups sysconsole_write_user_management_system_roles sysconsole_read_compliance_data_retention_policy order_bookmark_public_channel manage_custom_group_members list_team_channels sysconsole_read_integrations_bot_accounts upload_file sysconsole_write_site_notifications manage_oauth edit_brand use_slash_commands sysconsole_read_experimental_features sysconsole_read_site_public_links sysconsole_write_authentication_guest_access read_jobs playbook_public_manage_properties sysconsole_read_authentication_openid join_public_teams sysconsole_write_site_ip_filters sysconsole_read_environment_smtp add_ldap_public_cert	t	t
3ksurjrk8irhig93bfbbfu4i3w	system_user_manager	authentication.roles.system_user_manager.name	authentication.roles.system_user_manager.description	1769537458631	1769537459026	0	 manage_public_channel_properties convert_private_channel_to_public sysconsole_read_authentication_openid sysconsole_read_authentication_signup delete_private_channel view_team sysconsole_read_authentication_saml remove_user_from_team sysconsole_write_user_management_channels manage_public_channel_members read_public_channel manage_team sysconsole_read_authentication_ldap read_public_channel_groups sysconsole_read_user_management_teams sysconsole_read_authentication_password convert_public_channel_to_private manage_private_channel_members delete_public_channel sysconsole_read_authentication_email add_user_to_team read_private_channel_groups manage_team_roles test_ldap sysconsole_read_user_management_groups join_private_teams sysconsole_write_user_management_teams manage_private_channel_properties list_public_teams read_ldap_sync_job manage_channel_roles list_private_teams sysconsole_write_user_management_groups sysconsole_read_user_management_channels sysconsole_read_authentication_guest_access sysconsole_read_authentication_mfa read_channel sysconsole_read_user_management_permissions join_public_teams	f	t
np849u74jtni3gdjhwf97jud9h	system_manager	authentication.roles.system_manager.name	authentication.roles.system_manager.description	1769537458639	1769537459028	0	 sysconsole_write_site_posts delete_public_channel sysconsole_read_environment_file_storage sysconsole_read_user_management_channels read_elasticsearch_post_aggregation_job sysconsole_write_site_file_sharing_and_downloads sysconsole_read_site_public_links sysconsole_write_environment_logging sysconsole_read_environment_image_proxy sysconsole_read_environment_logging sysconsole_write_environment_image_proxy sysconsole_read_authentication_mfa sysconsole_read_authentication_ldap sysconsole_read_authentication_guest_access sysconsole_write_environment_web_server sysconsole_write_site_localization sysconsole_read_reporting_team_statistics test_elasticsearch edit_brand sysconsole_read_authentication_saml manage_elasticsearch_post_aggregation_job test_site_url sysconsole_read_about_edition_and_license sysconsole_read_user_management_permissions sysconsole_write_products_boards sysconsole_write_environment_elasticsearch manage_private_channel_members sysconsole_read_environment_elasticsearch sysconsole_read_site_notices manage_channel_roles sysconsole_read_site_users_and_teams read_private_channel_groups sysconsole_write_user_management_teams list_public_teams sysconsole_write_site_customization sysconsole_read_integrations_integration_management sysconsole_read_site_posts create_elasticsearch_post_indexing_job sysconsole_write_site_announcement_banner sysconsole_read_site_localization sysconsole_write_environment_push_notification_server sysconsole_read_site_emoji sysconsole_write_site_users_and_teams sysconsole_read_environment_rate_limiting sysconsole_read_authentication_email sysconsole_write_integrations_gif sysconsole_read_user_management_groups sysconsole_read_environment_performance_monitoring sysconsole_read_user_management_teams sysconsole_read_environment_session_lengths sysconsole_write_user_management_channels sysconsole_write_user_management_groups create_elasticsearch_post_aggregation_job sysconsole_read_authentication_signup read_ldap_sync_job add_user_to_team test_email manage_team_roles convert_public_channel_to_private purge_elasticsearch_indexes list_private_teams get_logs remove_user_from_team join_public_teams manage_public_channel_properties manage_elasticsearch_post_indexing_job sysconsole_read_environment_smtp sysconsole_write_site_public_links sysconsole_read_site_announcement_banner read_channel view_team sysconsole_read_environment_high_availability sysconsole_write_site_notifications sysconsole_read_products_boards invalidate_caches sysconsole_write_integrations_bot_accounts sysconsole_read_integrations_bot_accounts read_public_channel_groups sysconsole_read_site_notifications sysconsole_write_integrations_cors sysconsole_write_environment_developer sysconsole_read_site_file_sharing_and_downloads sysconsole_read_authentication_password get_analytics delete_private_channel sysconsole_write_environment_high_availability read_license_information sysconsole_read_site_customization sysconsole_write_environment_smtp test_s3 convert_private_channel_to_public join_private_teams manage_public_channel_members sysconsole_write_environment_performance_monitoring manage_outgoing_oauth_connections recycle_database_connections reload_config read_elasticsearch_post_indexing_job manage_team sysconsole_write_environment_session_lengths sysconsole_read_integrations_gif sysconsole_write_environment_database sysconsole_write_environment_file_storage sysconsole_write_environment_rate_limiting sysconsole_write_integrations_integration_management sysconsole_read_integrations_cors sysconsole_read_reporting_server_logs sysconsole_read_environment_database sysconsole_write_site_notices sysconsole_read_environment_web_server sysconsole_read_plugins sysconsole_read_environment_push_notification_server sysconsole_read_reporting_site_statistics sysconsole_read_authentication_openid sysconsole_read_environment_developer sysconsole_write_user_management_permissions read_public_channel test_ldap manage_private_channel_properties sysconsole_write_site_emoji	f	t
\.


--
-- Data for Name: scheduledposts; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.scheduledposts (id, createat, updateat, userid, channelid, rootid, message, props, fileids, priority, scheduledat, processedat, errorcode) FROM stdin;
\.


--
-- Data for Name: schemes; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.schemes (id, name, displayname, description, createat, updateat, deleteat, scope, defaultteamadminrole, defaultteamuserrole, defaultchanneladminrole, defaultchanneluserrole, defaultteamguestrole, defaultchannelguestrole, defaultplaybookadminrole, defaultplaybookmemberrole, defaultrunadminrole, defaultrunmemberrole) FROM stdin;
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.sessions (id, token, createat, expiresat, lastactivityat, userid, deviceid, roles, isoauth, props, expirednotify) FROM stdin;
8mi7tem653bfjmkny53pyp1dgy	mc3pitkdo7nw58je593j4354oy	1769537463256	0	1769537463256	ij3wiur3kib8mnwfmwetxqyrzr			f	{}	f
3x3xsso9xbdmdj3dryygp4wc4h	nrar66gsa3bg9gccmstwxctnow	1771642473703	0	1771642473703	ij3wiur3kib8mnwfmwetxqyrzr			f	{}	f
o5f3m7y1wbgytg1o38s4hknxey	xnzapzud6pr3m89br7qhwfcghc	1771646013609	0	1771646013609	ij3wiur3kib8mnwfmwetxqyrzr			f	{}	f
\.


--
-- Data for Name: sharedchannelattachments; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.sharedchannelattachments (id, fileid, remoteid, createat, lastsyncat) FROM stdin;
\.


--
-- Data for Name: sharedchannelremotes; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.sharedchannelremotes (id, channelid, creatorid, createat, updateat, isinviteaccepted, isinviteconfirmed, remoteid, lastpostupdateat, lastpostid, lastpostcreateat, lastpostcreateid, deleteat) FROM stdin;
\.


--
-- Data for Name: sharedchannels; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.sharedchannels (channelid, teamid, home, readonly, sharename, sharedisplayname, sharepurpose, shareheader, creatorid, createat, updateat, remoteid) FROM stdin;
\.


--
-- Data for Name: sharedchannelusers; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.sharedchannelusers (id, userid, remoteid, createat, lastsyncat, channelid) FROM stdin;
\.


--
-- Data for Name: sidebarcategories; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.sidebarcategories (id, userid, teamid, sortorder, sorting, type, displayname, muted, collapsed) FROM stdin;
favorites_ctz5686fy7fe5r3kfp8ckhp5yw_urj86b44zineig6jtetjez8qww	ctz5686fy7fe5r3kfp8ckhp5yw	urj86b44zineig6jtetjez8qww	0		favorites	Favorites	f	f
channels_ctz5686fy7fe5r3kfp8ckhp5yw_urj86b44zineig6jtetjez8qww	ctz5686fy7fe5r3kfp8ckhp5yw	urj86b44zineig6jtetjez8qww	10		channels	Channels	f	f
direct_messages_ctz5686fy7fe5r3kfp8ckhp5yw_urj86b44zineig6jtetjez8qww	ctz5686fy7fe5r3kfp8ckhp5yw	urj86b44zineig6jtetjez8qww	20	recent	direct_messages	Direct Messages	f	f
favorites_arf1sprce7nq3qnjh1hsac91nw_urj86b44zineig6jtetjez8qww	arf1sprce7nq3qnjh1hsac91nw	urj86b44zineig6jtetjez8qww	0		favorites	Favorites	f	f
channels_arf1sprce7nq3qnjh1hsac91nw_urj86b44zineig6jtetjez8qww	arf1sprce7nq3qnjh1hsac91nw	urj86b44zineig6jtetjez8qww	10		channels	Channels	f	f
direct_messages_arf1sprce7nq3qnjh1hsac91nw_urj86b44zineig6jtetjez8qww	arf1sprce7nq3qnjh1hsac91nw	urj86b44zineig6jtetjez8qww	20	recent	direct_messages	Direct Messages	f	f
favorites_arf1sprce7nq3qnjh1hsac91nw_nehyf6um5pfg7ejqkk4ccumroc	arf1sprce7nq3qnjh1hsac91nw	nehyf6um5pfg7ejqkk4ccumroc	0		favorites	Favorites	f	f
channels_arf1sprce7nq3qnjh1hsac91nw_nehyf6um5pfg7ejqkk4ccumroc	arf1sprce7nq3qnjh1hsac91nw	nehyf6um5pfg7ejqkk4ccumroc	10		channels	Channels	f	f
direct_messages_arf1sprce7nq3qnjh1hsac91nw_nehyf6um5pfg7ejqkk4ccumroc	arf1sprce7nq3qnjh1hsac91nw	nehyf6um5pfg7ejqkk4ccumroc	20	recent	direct_messages	Direct Messages	f	f
favorites_gud7udwfobn3pnu8x81ef7rxna_urj86b44zineig6jtetjez8qww	gud7udwfobn3pnu8x81ef7rxna	urj86b44zineig6jtetjez8qww	0		favorites	Favorites	f	f
channels_gud7udwfobn3pnu8x81ef7rxna_urj86b44zineig6jtetjez8qww	gud7udwfobn3pnu8x81ef7rxna	urj86b44zineig6jtetjez8qww	10		channels	Channels	f	f
direct_messages_gud7udwfobn3pnu8x81ef7rxna_urj86b44zineig6jtetjez8qww	gud7udwfobn3pnu8x81ef7rxna	urj86b44zineig6jtetjez8qww	20	recent	direct_messages	Direct Messages	f	f
favorites_6zwwofjeipryzeon9xpnuq84xy_urj86b44zineig6jtetjez8qww	6zwwofjeipryzeon9xpnuq84xy	urj86b44zineig6jtetjez8qww	0		favorites	Favorites	f	f
channels_6zwwofjeipryzeon9xpnuq84xy_urj86b44zineig6jtetjez8qww	6zwwofjeipryzeon9xpnuq84xy	urj86b44zineig6jtetjez8qww	10		channels	Channels	f	f
direct_messages_6zwwofjeipryzeon9xpnuq84xy_urj86b44zineig6jtetjez8qww	6zwwofjeipryzeon9xpnuq84xy	urj86b44zineig6jtetjez8qww	20	recent	direct_messages	Direct Messages	f	f
favorites_jueqmzyedbruppmb8u956ykphe_urj86b44zineig6jtetjez8qww	jueqmzyedbruppmb8u956ykphe	urj86b44zineig6jtetjez8qww	0		favorites	Favorites	f	f
channels_jueqmzyedbruppmb8u956ykphe_urj86b44zineig6jtetjez8qww	jueqmzyedbruppmb8u956ykphe	urj86b44zineig6jtetjez8qww	10		channels	Channels	f	f
direct_messages_jueqmzyedbruppmb8u956ykphe_urj86b44zineig6jtetjez8qww	jueqmzyedbruppmb8u956ykphe	urj86b44zineig6jtetjez8qww	20	recent	direct_messages	Direct Messages	f	f
favorites_ba1chd3qnprj5jx1tw6goqy4iy_urj86b44zineig6jtetjez8qww	ba1chd3qnprj5jx1tw6goqy4iy	urj86b44zineig6jtetjez8qww	0		favorites	Favorites	f	f
channels_ba1chd3qnprj5jx1tw6goqy4iy_urj86b44zineig6jtetjez8qww	ba1chd3qnprj5jx1tw6goqy4iy	urj86b44zineig6jtetjez8qww	10		channels	Channels	f	f
direct_messages_ba1chd3qnprj5jx1tw6goqy4iy_urj86b44zineig6jtetjez8qww	ba1chd3qnprj5jx1tw6goqy4iy	urj86b44zineig6jtetjez8qww	20	recent	direct_messages	Direct Messages	f	f
favorites_ba1chd3qnprj5jx1tw6goqy4iy_nehyf6um5pfg7ejqkk4ccumroc	ba1chd3qnprj5jx1tw6goqy4iy	nehyf6um5pfg7ejqkk4ccumroc	0		favorites	Favorites	f	f
channels_ba1chd3qnprj5jx1tw6goqy4iy_nehyf6um5pfg7ejqkk4ccumroc	ba1chd3qnprj5jx1tw6goqy4iy	nehyf6um5pfg7ejqkk4ccumroc	10		channels	Channels	f	f
direct_messages_ba1chd3qnprj5jx1tw6goqy4iy_nehyf6um5pfg7ejqkk4ccumroc	ba1chd3qnprj5jx1tw6goqy4iy	nehyf6um5pfg7ejqkk4ccumroc	20	recent	direct_messages	Direct Messages	f	f
favorites_j4i1gcm7stni8cqyhqixaexejw_urj86b44zineig6jtetjez8qww	j4i1gcm7stni8cqyhqixaexejw	urj86b44zineig6jtetjez8qww	0		favorites	Favorites	f	f
channels_j4i1gcm7stni8cqyhqixaexejw_urj86b44zineig6jtetjez8qww	j4i1gcm7stni8cqyhqixaexejw	urj86b44zineig6jtetjez8qww	10		channels	Channels	f	f
direct_messages_j4i1gcm7stni8cqyhqixaexejw_urj86b44zineig6jtetjez8qww	j4i1gcm7stni8cqyhqixaexejw	urj86b44zineig6jtetjez8qww	20	recent	direct_messages	Direct Messages	f	f
favorites_j4i1gcm7stni8cqyhqixaexejw_nehyf6um5pfg7ejqkk4ccumroc	j4i1gcm7stni8cqyhqixaexejw	nehyf6um5pfg7ejqkk4ccumroc	0		favorites	Favorites	f	f
channels_j4i1gcm7stni8cqyhqixaexejw_nehyf6um5pfg7ejqkk4ccumroc	j4i1gcm7stni8cqyhqixaexejw	nehyf6um5pfg7ejqkk4ccumroc	10		channels	Channels	f	f
direct_messages_j4i1gcm7stni8cqyhqixaexejw_nehyf6um5pfg7ejqkk4ccumroc	j4i1gcm7stni8cqyhqixaexejw	nehyf6um5pfg7ejqkk4ccumroc	20	recent	direct_messages	Direct Messages	f	f
favorites_7kzaisytntgidxic4jfr1yrg3y_urj86b44zineig6jtetjez8qww	7kzaisytntgidxic4jfr1yrg3y	urj86b44zineig6jtetjez8qww	0		favorites	Favorites	f	f
channels_7kzaisytntgidxic4jfr1yrg3y_urj86b44zineig6jtetjez8qww	7kzaisytntgidxic4jfr1yrg3y	urj86b44zineig6jtetjez8qww	10		channels	Channels	f	f
direct_messages_7kzaisytntgidxic4jfr1yrg3y_urj86b44zineig6jtetjez8qww	7kzaisytntgidxic4jfr1yrg3y	urj86b44zineig6jtetjez8qww	20	recent	direct_messages	Direct Messages	f	f
favorites_7kzaisytntgidxic4jfr1yrg3y_nehyf6um5pfg7ejqkk4ccumroc	7kzaisytntgidxic4jfr1yrg3y	nehyf6um5pfg7ejqkk4ccumroc	0		favorites	Favorites	f	f
channels_7kzaisytntgidxic4jfr1yrg3y_nehyf6um5pfg7ejqkk4ccumroc	7kzaisytntgidxic4jfr1yrg3y	nehyf6um5pfg7ejqkk4ccumroc	10		channels	Channels	f	f
direct_messages_7kzaisytntgidxic4jfr1yrg3y_nehyf6um5pfg7ejqkk4ccumroc	7kzaisytntgidxic4jfr1yrg3y	nehyf6um5pfg7ejqkk4ccumroc	20	recent	direct_messages	Direct Messages	f	f
favorites_4d5pwx1uob8gdmgqmc3fs9hfpe_urj86b44zineig6jtetjez8qww	4d5pwx1uob8gdmgqmc3fs9hfpe	urj86b44zineig6jtetjez8qww	0		favorites	Favorites	f	f
channels_4d5pwx1uob8gdmgqmc3fs9hfpe_urj86b44zineig6jtetjez8qww	4d5pwx1uob8gdmgqmc3fs9hfpe	urj86b44zineig6jtetjez8qww	10		channels	Channels	f	f
direct_messages_4d5pwx1uob8gdmgqmc3fs9hfpe_urj86b44zineig6jtetjez8qww	4d5pwx1uob8gdmgqmc3fs9hfpe	urj86b44zineig6jtetjez8qww	20	recent	direct_messages	Direct Messages	f	f
favorites_3a17zh894jrgbpw9ixhpjsyc9h_urj86b44zineig6jtetjez8qww	3a17zh894jrgbpw9ixhpjsyc9h	urj86b44zineig6jtetjez8qww	0		favorites	Favorites	f	f
channels_3a17zh894jrgbpw9ixhpjsyc9h_urj86b44zineig6jtetjez8qww	3a17zh894jrgbpw9ixhpjsyc9h	urj86b44zineig6jtetjez8qww	10		channels	Channels	f	f
direct_messages_3a17zh894jrgbpw9ixhpjsyc9h_urj86b44zineig6jtetjez8qww	3a17zh894jrgbpw9ixhpjsyc9h	urj86b44zineig6jtetjez8qww	20	recent	direct_messages	Direct Messages	f	f
favorites_eeif4rm7q3rrig6u1qkcusw35h_urj86b44zineig6jtetjez8qww	eeif4rm7q3rrig6u1qkcusw35h	urj86b44zineig6jtetjez8qww	0		favorites	Favorites	f	f
channels_eeif4rm7q3rrig6u1qkcusw35h_urj86b44zineig6jtetjez8qww	eeif4rm7q3rrig6u1qkcusw35h	urj86b44zineig6jtetjez8qww	10		channels	Channels	f	f
direct_messages_eeif4rm7q3rrig6u1qkcusw35h_urj86b44zineig6jtetjez8qww	eeif4rm7q3rrig6u1qkcusw35h	urj86b44zineig6jtetjez8qww	20	recent	direct_messages	Direct Messages	f	f
favorites_eeif4rm7q3rrig6u1qkcusw35h_nehyf6um5pfg7ejqkk4ccumroc	eeif4rm7q3rrig6u1qkcusw35h	nehyf6um5pfg7ejqkk4ccumroc	0		favorites	Favorites	f	f
channels_eeif4rm7q3rrig6u1qkcusw35h_nehyf6um5pfg7ejqkk4ccumroc	eeif4rm7q3rrig6u1qkcusw35h	nehyf6um5pfg7ejqkk4ccumroc	10		channels	Channels	f	f
direct_messages_eeif4rm7q3rrig6u1qkcusw35h_nehyf6um5pfg7ejqkk4ccumroc	eeif4rm7q3rrig6u1qkcusw35h	nehyf6um5pfg7ejqkk4ccumroc	20	recent	direct_messages	Direct Messages	f	f
favorites_dr6nhfmd4iyp5dhfkkd1b1fy1h_urj86b44zineig6jtetjez8qww	dr6nhfmd4iyp5dhfkkd1b1fy1h	urj86b44zineig6jtetjez8qww	0		favorites	Favorites	f	f
channels_dr6nhfmd4iyp5dhfkkd1b1fy1h_urj86b44zineig6jtetjez8qww	dr6nhfmd4iyp5dhfkkd1b1fy1h	urj86b44zineig6jtetjez8qww	10		channels	Channels	f	f
direct_messages_dr6nhfmd4iyp5dhfkkd1b1fy1h_urj86b44zineig6jtetjez8qww	dr6nhfmd4iyp5dhfkkd1b1fy1h	urj86b44zineig6jtetjez8qww	20	recent	direct_messages	Direct Messages	f	f
favorites_q61z1nffcjbr9p1uf8zjyimqgr_urj86b44zineig6jtetjez8qww	q61z1nffcjbr9p1uf8zjyimqgr	urj86b44zineig6jtetjez8qww	0		favorites	Favorites	f	f
channels_q61z1nffcjbr9p1uf8zjyimqgr_urj86b44zineig6jtetjez8qww	q61z1nffcjbr9p1uf8zjyimqgr	urj86b44zineig6jtetjez8qww	10		channels	Channels	f	f
direct_messages_q61z1nffcjbr9p1uf8zjyimqgr_urj86b44zineig6jtetjez8qww	q61z1nffcjbr9p1uf8zjyimqgr	urj86b44zineig6jtetjez8qww	20	recent	direct_messages	Direct Messages	f	f
favorites_q61z1nffcjbr9p1uf8zjyimqgr_nehyf6um5pfg7ejqkk4ccumroc	q61z1nffcjbr9p1uf8zjyimqgr	nehyf6um5pfg7ejqkk4ccumroc	0		favorites	Favorites	f	f
channels_q61z1nffcjbr9p1uf8zjyimqgr_nehyf6um5pfg7ejqkk4ccumroc	q61z1nffcjbr9p1uf8zjyimqgr	nehyf6um5pfg7ejqkk4ccumroc	10		channels	Channels	f	f
direct_messages_q61z1nffcjbr9p1uf8zjyimqgr_nehyf6um5pfg7ejqkk4ccumroc	q61z1nffcjbr9p1uf8zjyimqgr	nehyf6um5pfg7ejqkk4ccumroc	20	recent	direct_messages	Direct Messages	f	f
favorites_1w1w87fzdin5fpdta4ra8h5opw_urj86b44zineig6jtetjez8qww	1w1w87fzdin5fpdta4ra8h5opw	urj86b44zineig6jtetjez8qww	0		favorites	Favorites	f	f
channels_1w1w87fzdin5fpdta4ra8h5opw_urj86b44zineig6jtetjez8qww	1w1w87fzdin5fpdta4ra8h5opw	urj86b44zineig6jtetjez8qww	10		channels	Channels	f	f
direct_messages_1w1w87fzdin5fpdta4ra8h5opw_urj86b44zineig6jtetjez8qww	1w1w87fzdin5fpdta4ra8h5opw	urj86b44zineig6jtetjez8qww	20	recent	direct_messages	Direct Messages	f	f
\.


--
-- Data for Name: sidebarchannels; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.sidebarchannels (channelid, userid, categoryid, sortorder) FROM stdin;
\.


--
-- Data for Name: status; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.status (userid, status, manual, lastactivityat, dndendtime, prevstatus) FROM stdin;
\.


--
-- Data for Name: systems; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.systems (name, value) FROM stdin;
CRTChannelMembershipCountsMigrationComplete	true
CRTThreadCountsAndUnreadsMigrationComplete	true
AsymmetricSigningKey	{"ecdsa_key":{"curve":"P-256","x":12846228203446416558483637517037032795312828484604049542739711147001372173389,"y":65029604055585999519540091852397951871319416718960942775096414096202622918125,"d":75616589839382888480014174354162628734172566200787146290612369114615271848102}}
DiagnosticId	zbrafnry63yyjppca9ek67qjmy
FirstServerRunTimestamp	1769537458624
AdvancedPermissionsMigrationComplete	true
EmojisPermissionsMigrationComplete	true
GuestRolesCreationMigrationComplete	true
SystemConsoleRolesCreationMigrationComplete	true
CustomGroupAdminRoleCreationMigrationComplete	true
emoji_permissions_split	true
webhook_permissions_split	true
list_join_public_private_teams	true
remove_permanent_delete_user	true
add_bot_permissions	true
apply_channel_manage_delete_to_channel_user	true
remove_channel_manage_delete_from_team_user	true
view_members_new_permission	true
add_manage_guests_permissions	true
channel_moderations_permissions	true
add_use_group_mentions_permission	true
add_system_console_permissions	true
add_convert_channel_permissions	true
manage_shared_channel_permissions	true
manage_secure_connections_permissions	true
add_system_roles_permissions	true
add_billing_permissions	true
download_compliance_export_results	true
experimental_subsection_permissions	true
authentication_subsection_permissions	true
integrations_subsection_permissions	true
site_subsection_permissions	true
compliance_subsection_permissions	true
environment_subsection_permissions	true
about_subsection_permissions	true
reporting_subsection_permissions	true
test_email_ancillary_permission	true
playbooks_permissions	true
custom_groups_permissions	true
playbooks_manage_roles	true
products_boards	true
custom_groups_permission_restore	true
read_channel_content_permissions	true
add_ip_filtering_permissions	true
add_outgoing_oauth_connections_permissions	true
add_channel_bookmarks_permissions	true
add_manage_jobs_ancillary_permissions	true
add_upload_file_permission	true
restrict_access_to_channel_conversion_to_public_permissions	true
fix_read_audits_permission	true
remove_get_analytics_permission	true
ContentExtractionConfigDefaultTrueMigrationComplete	true
PlaybookRolesCreationMigrationComplete	true
RemainingSchemaMigrations	true
PostPriorityConfigDefaultTrueMigrationComplete	true
PostActionCookieSecret	{"key":"7pZUsEC+2/tl7+11tsHaBbFJPMpOwnHmaHtC2NI4YUg="}
InstallationDate	1769537460510
delete_dms_preferences_migration	true
delete_empty_drafts_migration	true
delete_orphan_drafts_migration	true
migration_advanced_permissions_phase_2	true
LastSecurityTime	1771642471665
FirstAdminSetupComplete	true
\.


--
-- Data for Name: teammembers; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.teammembers (teamid, userid, roles, deleteat, schemeuser, schemeadmin, schemeguest, createat) FROM stdin;
nehyf6um5pfg7ejqkk4ccumroc	7kzaisytntgidxic4jfr1yrg3y		0	t	f	f	1769537510935
nehyf6um5pfg7ejqkk4ccumroc	arf1sprce7nq3qnjh1hsac91nw		0	t	f	f	1769537498626
nehyf6um5pfg7ejqkk4ccumroc	ba1chd3qnprj5jx1tw6goqy4iy		0	t	f	f	1769537506498
nehyf6um5pfg7ejqkk4ccumroc	eeif4rm7q3rrig6u1qkcusw35h		0	t	f	f	1769537516953
nehyf6um5pfg7ejqkk4ccumroc	j4i1gcm7stni8cqyhqixaexejw		0	t	f	f	1769537508653
nehyf6um5pfg7ejqkk4ccumroc	q61z1nffcjbr9p1uf8zjyimqgr		0	t	f	f	1769537519114
urj86b44zineig6jtetjez8qww	1w1w87fzdin5fpdta4ra8h5opw		0	t	f	f	1769537527861
urj86b44zineig6jtetjez8qww	3a17zh894jrgbpw9ixhpjsyc9h		0	t	f	f	1769537514767
urj86b44zineig6jtetjez8qww	4d5pwx1uob8gdmgqmc3fs9hfpe		0	t	f	f	1769537512857
urj86b44zineig6jtetjez8qww	6zwwofjeipryzeon9xpnuq84xy		0	t	f	f	1769537502448
urj86b44zineig6jtetjez8qww	7kzaisytntgidxic4jfr1yrg3y		0	t	f	f	1769537510544
urj86b44zineig6jtetjez8qww	arf1sprce7nq3qnjh1hsac91nw		0	t	f	f	1769537498264
urj86b44zineig6jtetjez8qww	ba1chd3qnprj5jx1tw6goqy4iy		0	t	f	f	1769537506139
urj86b44zineig6jtetjez8qww	ctz5686fy7fe5r3kfp8ckhp5yw		0	t	f	f	1769537496247
urj86b44zineig6jtetjez8qww	dr6nhfmd4iyp5dhfkkd1b1fy1h		0	t	f	f	1769537520995
urj86b44zineig6jtetjez8qww	eeif4rm7q3rrig6u1qkcusw35h		0	t	f	f	1769537516608
urj86b44zineig6jtetjez8qww	gud7udwfobn3pnu8x81ef7rxna		0	t	f	f	1769537500555
urj86b44zineig6jtetjez8qww	j4i1gcm7stni8cqyhqixaexejw		0	t	f	f	1769537508319
urj86b44zineig6jtetjez8qww	jueqmzyedbruppmb8u956ykphe		0	t	f	f	1769537504302
urj86b44zineig6jtetjez8qww	q61z1nffcjbr9p1uf8zjyimqgr		0	t	f	f	1769537518770
\.


--
-- Data for Name: teams; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.teams (id, createat, updateat, deleteat, displayname, name, description, email, type, companyname, alloweddomains, inviteid, schemeid, allowopeninvite, lastteamiconupdate, groupconstrained, cloudlimitsarchived) FROM stdin;
urj86b44zineig6jtetjez8qww	1769537494436	1769537494436	0	Zoo	zoo			O			urcbjxdxcfg4pgq7j9oh1dkaca	\N	t	0	\N	f
nehyf6um5pfg7ejqkk4ccumroc	1769537494965	1769537494965	0	Platform Team	platform			I			za6p9owfmby6dcdphqfminc9rh	\N	f	0	\N	f
\.


--
-- Data for Name: termsofservice; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.termsofservice (id, createat, userid, text) FROM stdin;
\.


--
-- Data for Name: threadmemberships; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.threadmemberships (postid, userid, following, lastviewed, lastupdated, unreadmentions) FROM stdin;
\.


--
-- Data for Name: threads; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.threads (postid, replycount, lastreplyat, participants, channelid, threaddeleteat, threadteamid) FROM stdin;
\.


--
-- Data for Name: tokens; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.tokens (token, createat, type, extra) FROM stdin;
\.


--
-- Data for Name: uploadsessions; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.uploadsessions (id, type, createat, userid, channelid, filename, path, filesize, fileoffset, remoteid, reqfileid) FROM stdin;
\.


--
-- Data for Name: useraccesstokens; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.useraccesstokens (id, token, userid, description, isactive) FROM stdin;
\.


--
-- Data for Name: usergroups; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.usergroups (id, name, displayname, description, source, remoteid, createat, updateat, deleteat, allowreference) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.users (id, createat, updateat, deleteat, username, password, authdata, authservice, email, emailverified, nickname, firstname, lastname, roles, allowmarketing, props, notifyprops, lastpasswordupdate, lastpictureupdate, failedattempts, locale, mfaactive, mfasecret, "position", timezone, remoteid, lastlogin, mfausedtimestamps) FROM stdin;
dyt7tnqg8p8mxqnm3r417ikwtw	1769537462533	1769537462555	0	feedbackbot		\N		feedbackbot@localhost	f		Feedbackbot		system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1769537462533	1769537462555	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}	\N	0	null
ij3wiur3kib8mnwfmwetxqyrzr	1769537463243	1771642778594	0	calls		\N		calls@localhost	f		Calls		system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1769537463243	1771642778594	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}	\N	0	null
ctz5686fy7fe5r3kfp8ckhp5yw	1769537495325	1771646035695	0	admin	$2a$10$kbrRfOtISVl6qKhXAEGoj.MP5FBdHRXmoHqfj5NveisCW8RQupt0e	\N		admin@snappymail.zoo	f				system_user system_admin	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1771646035695	0	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		0	[]
arf1sprce7nq3qnjh1hsac91nw	1769537497402	1771646037895	0	alice	$2a$10$2SyyYV5HQEWB55DqpK.15etbEzT30S02jFWBMz24qftQrCVVv1eKS	\N		alice@snappymail.zoo	f				system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1771646037895	0	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		0	[]
gud7udwfobn3pnu8x81ef7rxna	1769537499721	1771646040419	0	bob	$2a$10$f96e7njY6UCn9ZdZKt8XtuLNG87mWMpL1vchZWeyCuDEBbqGzRHlK	\N		bob@snappymail.zoo	f				system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1771646040419	0	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		0	[]
6zwwofjeipryzeon9xpnuq84xy	1769537501587	1771646042643	0	charlie	$2a$10$U5GBpB6obBllREgG0F0JXuSKrC.mjSo8sobdBa.7zINZR/wpWKdjO	\N		charlie@snappymail.zoo	f				system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1771646042643	0	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		0	[]
jueqmzyedbruppmb8u956ykphe	1769537503482	1771646044860	0	diana	$2a$10$mN2bGqMfjnOIyaofi4pGA.S2cEVss1wXeTCstPkL8oof9zRLOACoW	\N		diana@snappymail.zoo	f				system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1771646044860	0	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		0	[]
ba1chd3qnprj5jx1tw6goqy4iy	1769537505329	1771646047071	0	eve	$2a$10$0Ok27fIrF3B7TvAnDJ9BEelB2IqleTRFJ2DoAn7XUkAH2Frv9LLce	\N		eve@snappymail.zoo	f				system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1771646047071	0	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		0	[]
j4i1gcm7stni8cqyhqixaexejw	1769537507522	1771646049572	0	frank	$2a$10$a5ZpIc2F.RQLtRY25bUW3.T12egEabnvLAHBq5P531/WjPckz9E.i	\N		frank@snappymail.zoo	f				system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1771646049572	0	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		0	[]
7kzaisytntgidxic4jfr1yrg3y	1769537509689	1771646052092	0	grace	$2a$10$iMXLUN3JsU9igurHgTIBOONexoT712pq598Gb6320s0AVv9lVcmwC	\N		grace@snappymail.zoo	f				system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1771646052092	0	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		0	[]
4d5pwx1uob8gdmgqmc3fs9hfpe	1769537512033	1771646054653	0	demo	$2a$10$ToDlOB5ftaLxjSEMPZnCvuYuC.Zad4dIyhE.9q6/LDTFmV5n1Rs0q	\N		demo@snappymail.zoo	f				system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1771646054653	0	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		0	[]
3a17zh894jrgbpw9ixhpjsyc9h	1769537513926	1771646056854	0	user1	$2a$10$JuMBF6XSTD/.Uuad28Q5IeBVUkeAHB0cX0V5skeStIZHwKsT.j46W	\N		user1@snappymail.zoo	f				system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1771646056854	0	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		0	[]
osi5d4mhzjdt7qiza78d5i38sw	1771642500003	1771642500003	0	system-bot		\N		system-bot@localhost	f		System		system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1771642500003	0	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}	\N	0	null
oi9jhtfswpbtbfotpsuuj71zuc	1769537460510	1771642778500	0	playbooks		\N		playbooks@localhost	f		Playbooks		system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1769537460510	1771642778500	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}	\N	0	null
q61z1nffcjbr9p1uf8zjyimqgr	1769537517995	1771646061577	0	blake.sullivan	$2a$10$bOY72er9jb7Mjg4RWqSULuoWAN1OM2sJsOxE6/l7sGZaut5xrazLK	\N		blake.sullivan@snappymail.zoo	f				system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1771646061577	0	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		0	[]
dr6nhfmd4iyp5dhfkkd1b1fy1h	1769537520186	1771646064106	0	mallory	$2a$10$6OtXfArFSjJiUtZK.vnndeoYRKjukCs1s6.xlHglxoAX3mtVkdlNe	\N		mallory@snappymail.zoo	f				system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1771646064106	0	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		0	[]
1w1w87fzdin5fpdta4ra8h5opw	1769537522021	1771646066329	0	analytics_user	$2a$10$Q5AKqIAaD0Ir8vMW9DAF0udBxumLSeFvbNGMzAV6.T3drd18q45ci	\N		analytics_user@snappymail.zoo	f				system_user system_admin	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1771646066329	0	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		0	[]
eeif4rm7q3rrig6u1qkcusw35h	1769537515790	1771646059052	0	alex.chen	$2a$10$g5ohC57OrtxB/act7c8uJeAKwPgAPA4JbQLwwIcB7dqCsjsUFQFPS	\N		alex.chen@snappymail.zoo	f				system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1771646059052	0	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		0	[]
\.


--
-- Data for Name: usertermsofservice; Type: TABLE DATA; Schema: public; Owner: mattermost_user
--

COPY public.usertermsofservice (userid, termsofserviceid, createat) FROM stdin;
\.


--
-- Name: audits audits_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.audits
    ADD CONSTRAINT audits_pkey PRIMARY KEY (id);


--
-- Name: bots bots_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.bots
    ADD CONSTRAINT bots_pkey PRIMARY KEY (userid);


--
-- Name: calls_channels calls_channels_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.calls_channels
    ADD CONSTRAINT calls_channels_pkey PRIMARY KEY (channelid);


--
-- Name: calls_jobs calls_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.calls_jobs
    ADD CONSTRAINT calls_jobs_pkey PRIMARY KEY (id);


--
-- Name: calls calls_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.calls
    ADD CONSTRAINT calls_pkey PRIMARY KEY (id);


--
-- Name: calls_sessions calls_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.calls_sessions
    ADD CONSTRAINT calls_sessions_pkey PRIMARY KEY (id);


--
-- Name: channelbookmarks channelbookmarks_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.channelbookmarks
    ADD CONSTRAINT channelbookmarks_pkey PRIMARY KEY (id);


--
-- Name: channelmemberhistory channelmemberhistory_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.channelmemberhistory
    ADD CONSTRAINT channelmemberhistory_pkey PRIMARY KEY (channelid, userid, jointime);


--
-- Name: channelmembers channelmembers_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.channelmembers
    ADD CONSTRAINT channelmembers_pkey PRIMARY KEY (channelid, userid);


--
-- Name: channels channels_name_teamid_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.channels
    ADD CONSTRAINT channels_name_teamid_key UNIQUE (name, teamid);


--
-- Name: channels channels_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.channels
    ADD CONSTRAINT channels_pkey PRIMARY KEY (id);


--
-- Name: clusterdiscovery clusterdiscovery_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.clusterdiscovery
    ADD CONSTRAINT clusterdiscovery_pkey PRIMARY KEY (id);


--
-- Name: commands commands_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.commands
    ADD CONSTRAINT commands_pkey PRIMARY KEY (id);


--
-- Name: commandwebhooks commandwebhooks_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.commandwebhooks
    ADD CONSTRAINT commandwebhooks_pkey PRIMARY KEY (id);


--
-- Name: compliances compliances_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.compliances
    ADD CONSTRAINT compliances_pkey PRIMARY KEY (id);


--
-- Name: configurationfiles configurationfiles_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.configurationfiles
    ADD CONSTRAINT configurationfiles_pkey PRIMARY KEY (name);


--
-- Name: configurations configurations_active_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.configurations
    ADD CONSTRAINT configurations_active_key UNIQUE (active);


--
-- Name: configurations configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.configurations
    ADD CONSTRAINT configurations_pkey PRIMARY KEY (id);


--
-- Name: db_config_migrations db_config_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.db_config_migrations
    ADD CONSTRAINT db_config_migrations_pkey PRIMARY KEY (version);


--
-- Name: db_lock db_lock_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.db_lock
    ADD CONSTRAINT db_lock_pkey PRIMARY KEY (id);


--
-- Name: db_migrations_calls db_migrations_calls_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.db_migrations_calls
    ADD CONSTRAINT db_migrations_calls_pkey PRIMARY KEY (version);


--
-- Name: db_migrations db_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.db_migrations
    ADD CONSTRAINT db_migrations_pkey PRIMARY KEY (version);


--
-- Name: desktoptokens desktoptokens_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.desktoptokens
    ADD CONSTRAINT desktoptokens_pkey PRIMARY KEY (token);


--
-- Name: drafts drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_pkey PRIMARY KEY (userid, channelid, rootid);


--
-- Name: emoji emoji_name_deleteat_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.emoji
    ADD CONSTRAINT emoji_name_deleteat_key UNIQUE (name, deleteat);


--
-- Name: emoji emoji_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.emoji
    ADD CONSTRAINT emoji_pkey PRIMARY KEY (id);


--
-- Name: fileinfo fileinfo_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.fileinfo
    ADD CONSTRAINT fileinfo_pkey PRIMARY KEY (id);


--
-- Name: groupchannels groupchannels_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.groupchannels
    ADD CONSTRAINT groupchannels_pkey PRIMARY KEY (groupid, channelid);


--
-- Name: groupmembers groupmembers_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.groupmembers
    ADD CONSTRAINT groupmembers_pkey PRIMARY KEY (groupid, userid);


--
-- Name: groupteams groupteams_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.groupteams
    ADD CONSTRAINT groupteams_pkey PRIMARY KEY (groupid, teamid);


--
-- Name: incomingwebhooks incomingwebhooks_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.incomingwebhooks
    ADD CONSTRAINT incomingwebhooks_pkey PRIMARY KEY (id);


--
-- Name: ir_category_item ir_category_item_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_category_item
    ADD CONSTRAINT ir_category_item_pkey PRIMARY KEY (categoryid, itemid, type);


--
-- Name: ir_category ir_category_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_category
    ADD CONSTRAINT ir_category_pkey PRIMARY KEY (id);


--
-- Name: ir_channelaction ir_channelaction_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_channelaction
    ADD CONSTRAINT ir_channelaction_pkey PRIMARY KEY (id);


--
-- Name: ir_incident ir_incident_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_incident
    ADD CONSTRAINT ir_incident_pkey PRIMARY KEY (id);


--
-- Name: ir_metric ir_metric_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_metric
    ADD CONSTRAINT ir_metric_pkey PRIMARY KEY (incidentid, metricconfigid);


--
-- Name: ir_metricconfig ir_metricconfig_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_metricconfig
    ADD CONSTRAINT ir_metricconfig_pkey PRIMARY KEY (id);


--
-- Name: ir_playbook ir_playbook_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_playbook
    ADD CONSTRAINT ir_playbook_pkey PRIMARY KEY (id);


--
-- Name: ir_playbookautofollow ir_playbookautofollow_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_playbookautofollow
    ADD CONSTRAINT ir_playbookautofollow_pkey PRIMARY KEY (playbookid, userid);


--
-- Name: ir_playbookmember ir_playbookmember_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_playbookmember
    ADD CONSTRAINT ir_playbookmember_pkey PRIMARY KEY (memberid, playbookid);


--
-- Name: ir_playbookmember ir_playbookmember_playbookid_memberid_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_playbookmember
    ADD CONSTRAINT ir_playbookmember_playbookid_memberid_key UNIQUE (playbookid, memberid);


--
-- Name: ir_run_participants ir_run_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_run_participants
    ADD CONSTRAINT ir_run_participants_pkey PRIMARY KEY (incidentid, userid);


--
-- Name: ir_statusposts ir_statusposts_incidentid_postid_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_statusposts
    ADD CONSTRAINT ir_statusposts_incidentid_postid_key UNIQUE (incidentid, postid);


--
-- Name: ir_statusposts ir_statusposts_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_statusposts
    ADD CONSTRAINT ir_statusposts_pkey PRIMARY KEY (incidentid, postid);


--
-- Name: ir_system ir_system_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_system
    ADD CONSTRAINT ir_system_pkey PRIMARY KEY (skey);


--
-- Name: ir_timelineevent ir_timelineevent_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_timelineevent
    ADD CONSTRAINT ir_timelineevent_pkey PRIMARY KEY (id);


--
-- Name: ir_userinfo ir_userinfo_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_userinfo
    ADD CONSTRAINT ir_userinfo_pkey PRIMARY KEY (id);


--
-- Name: ir_viewedchannel ir_viewedchannel_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_viewedchannel
    ADD CONSTRAINT ir_viewedchannel_pkey PRIMARY KEY (channelid, userid);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: licenses licenses_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.licenses
    ADD CONSTRAINT licenses_pkey PRIMARY KEY (id);


--
-- Name: linkmetadata linkmetadata_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.linkmetadata
    ADD CONSTRAINT linkmetadata_pkey PRIMARY KEY (hash);


--
-- Name: llm_postmeta llm_postmeta_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.llm_postmeta
    ADD CONSTRAINT llm_postmeta_pkey PRIMARY KEY (rootpostid);


--
-- Name: notifyadmin notifyadmin_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.notifyadmin
    ADD CONSTRAINT notifyadmin_pkey PRIMARY KEY (userid, requiredfeature, requiredplan);


--
-- Name: oauthaccessdata oauthaccessdata_clientid_userid_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.oauthaccessdata
    ADD CONSTRAINT oauthaccessdata_clientid_userid_key UNIQUE (clientid, userid);


--
-- Name: oauthaccessdata oauthaccessdata_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.oauthaccessdata
    ADD CONSTRAINT oauthaccessdata_pkey PRIMARY KEY (token);


--
-- Name: oauthapps oauthapps_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.oauthapps
    ADD CONSTRAINT oauthapps_pkey PRIMARY KEY (id);


--
-- Name: oauthauthdata oauthauthdata_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.oauthauthdata
    ADD CONSTRAINT oauthauthdata_pkey PRIMARY KEY (code);


--
-- Name: outgoingoauthconnections outgoingoauthconnections_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.outgoingoauthconnections
    ADD CONSTRAINT outgoingoauthconnections_pkey PRIMARY KEY (id);


--
-- Name: outgoingwebhooks outgoingwebhooks_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.outgoingwebhooks
    ADD CONSTRAINT outgoingwebhooks_pkey PRIMARY KEY (id);


--
-- Name: persistentnotifications persistentnotifications_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.persistentnotifications
    ADD CONSTRAINT persistentnotifications_pkey PRIMARY KEY (postid);


--
-- Name: pluginkeyvaluestore pluginkeyvaluestore_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.pluginkeyvaluestore
    ADD CONSTRAINT pluginkeyvaluestore_pkey PRIMARY KEY (pluginid, pkey);


--
-- Name: postacknowledgements postacknowledgements_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.postacknowledgements
    ADD CONSTRAINT postacknowledgements_pkey PRIMARY KEY (postid, userid);


--
-- Name: postreminders postreminders_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.postreminders
    ADD CONSTRAINT postreminders_pkey PRIMARY KEY (postid, userid);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: postspriority postspriority_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.postspriority
    ADD CONSTRAINT postspriority_pkey PRIMARY KEY (postid);


--
-- Name: preferences preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.preferences
    ADD CONSTRAINT preferences_pkey PRIMARY KEY (userid, category, name);


--
-- Name: productnoticeviewstate productnoticeviewstate_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.productnoticeviewstate
    ADD CONSTRAINT productnoticeviewstate_pkey PRIMARY KEY (userid, noticeid);


--
-- Name: propertyfields propertyfields_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.propertyfields
    ADD CONSTRAINT propertyfields_pkey PRIMARY KEY (id);


--
-- Name: propertygroups propertygroups_name_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.propertygroups
    ADD CONSTRAINT propertygroups_name_key UNIQUE (name);


--
-- Name: propertygroups propertygroups_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.propertygroups
    ADD CONSTRAINT propertygroups_pkey PRIMARY KEY (id);


--
-- Name: propertyvalues propertyvalues_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.propertyvalues
    ADD CONSTRAINT propertyvalues_pkey PRIMARY KEY (id);


--
-- Name: publicchannels publicchannels_name_teamid_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.publicchannels
    ADD CONSTRAINT publicchannels_name_teamid_key UNIQUE (name, teamid);


--
-- Name: publicchannels publicchannels_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.publicchannels
    ADD CONSTRAINT publicchannels_pkey PRIMARY KEY (id);


--
-- Name: reactions reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.reactions
    ADD CONSTRAINT reactions_pkey PRIMARY KEY (postid, userid, emojiname);


--
-- Name: recentsearches recentsearches_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.recentsearches
    ADD CONSTRAINT recentsearches_pkey PRIMARY KEY (userid, searchpointer);


--
-- Name: remoteclusters remoteclusters_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.remoteclusters
    ADD CONSTRAINT remoteclusters_pkey PRIMARY KEY (remoteid, name);


--
-- Name: retentionidsfordeletion retentionidsfordeletion_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.retentionidsfordeletion
    ADD CONSTRAINT retentionidsfordeletion_pkey PRIMARY KEY (id);


--
-- Name: retentionpolicies retentionpolicies_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.retentionpolicies
    ADD CONSTRAINT retentionpolicies_pkey PRIMARY KEY (id);


--
-- Name: retentionpolicieschannels retentionpolicieschannels_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.retentionpolicieschannels
    ADD CONSTRAINT retentionpolicieschannels_pkey PRIMARY KEY (channelid);


--
-- Name: retentionpoliciesteams retentionpoliciesteams_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.retentionpoliciesteams
    ADD CONSTRAINT retentionpoliciesteams_pkey PRIMARY KEY (teamid);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: scheduledposts scheduledposts_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.scheduledposts
    ADD CONSTRAINT scheduledposts_pkey PRIMARY KEY (id);


--
-- Name: schemes schemes_name_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.schemes
    ADD CONSTRAINT schemes_name_key UNIQUE (name);


--
-- Name: schemes schemes_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.schemes
    ADD CONSTRAINT schemes_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sharedchannelattachments sharedchannelattachments_fileid_remoteid_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.sharedchannelattachments
    ADD CONSTRAINT sharedchannelattachments_fileid_remoteid_key UNIQUE (fileid, remoteid);


--
-- Name: sharedchannelattachments sharedchannelattachments_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.sharedchannelattachments
    ADD CONSTRAINT sharedchannelattachments_pkey PRIMARY KEY (id);


--
-- Name: sharedchannelremotes sharedchannelremotes_channelid_remoteid_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.sharedchannelremotes
    ADD CONSTRAINT sharedchannelremotes_channelid_remoteid_key UNIQUE (channelid, remoteid);


--
-- Name: sharedchannelremotes sharedchannelremotes_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.sharedchannelremotes
    ADD CONSTRAINT sharedchannelremotes_pkey PRIMARY KEY (id, channelid);


--
-- Name: sharedchannels sharedchannels_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.sharedchannels
    ADD CONSTRAINT sharedchannels_pkey PRIMARY KEY (channelid);


--
-- Name: sharedchannels sharedchannels_sharename_teamid_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.sharedchannels
    ADD CONSTRAINT sharedchannels_sharename_teamid_key UNIQUE (sharename, teamid);


--
-- Name: sharedchannelusers sharedchannelusers_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.sharedchannelusers
    ADD CONSTRAINT sharedchannelusers_pkey PRIMARY KEY (id);


--
-- Name: sharedchannelusers sharedchannelusers_userid_channelid_remoteid_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.sharedchannelusers
    ADD CONSTRAINT sharedchannelusers_userid_channelid_remoteid_key UNIQUE (userid, channelid, remoteid);


--
-- Name: sidebarcategories sidebarcategories_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.sidebarcategories
    ADD CONSTRAINT sidebarcategories_pkey PRIMARY KEY (id);


--
-- Name: sidebarchannels sidebarchannels_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.sidebarchannels
    ADD CONSTRAINT sidebarchannels_pkey PRIMARY KEY (channelid, userid, categoryid);


--
-- Name: status status_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_pkey PRIMARY KEY (userid);


--
-- Name: systems systems_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.systems
    ADD CONSTRAINT systems_pkey PRIMARY KEY (name);


--
-- Name: teammembers teammembers_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.teammembers
    ADD CONSTRAINT teammembers_pkey PRIMARY KEY (teamid, userid);


--
-- Name: teams teams_name_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_name_key UNIQUE (name);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: termsofservice termsofservice_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.termsofservice
    ADD CONSTRAINT termsofservice_pkey PRIMARY KEY (id);


--
-- Name: threadmemberships threadmemberships_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.threadmemberships
    ADD CONSTRAINT threadmemberships_pkey PRIMARY KEY (postid, userid);


--
-- Name: threads threads_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.threads
    ADD CONSTRAINT threads_pkey PRIMARY KEY (postid);


--
-- Name: tokens tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (token);


--
-- Name: uploadsessions uploadsessions_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.uploadsessions
    ADD CONSTRAINT uploadsessions_pkey PRIMARY KEY (id);


--
-- Name: useraccesstokens useraccesstokens_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.useraccesstokens
    ADD CONSTRAINT useraccesstokens_pkey PRIMARY KEY (id);


--
-- Name: useraccesstokens useraccesstokens_token_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.useraccesstokens
    ADD CONSTRAINT useraccesstokens_token_key UNIQUE (token);


--
-- Name: usergroups usergroups_name_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.usergroups
    ADD CONSTRAINT usergroups_name_key UNIQUE (name);


--
-- Name: usergroups usergroups_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.usergroups
    ADD CONSTRAINT usergroups_pkey PRIMARY KEY (id);


--
-- Name: usergroups usergroups_source_remoteid_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.usergroups
    ADD CONSTRAINT usergroups_source_remoteid_key UNIQUE (source, remoteid);


--
-- Name: users users_authdata_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_authdata_key UNIQUE (authdata);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: usertermsofservice usertermsofservice_pkey; Type: CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.usertermsofservice
    ADD CONSTRAINT usertermsofservice_pkey PRIMARY KEY (userid);


--
-- Name: idx_audits_user_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_audits_user_id ON public.audits USING btree (userid);


--
-- Name: idx_calls_channel_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_calls_channel_id ON public.calls USING btree (channelid);


--
-- Name: idx_calls_end_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_calls_end_at ON public.calls USING btree (endat);


--
-- Name: idx_calls_jobs_call_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_calls_jobs_call_id ON public.calls_jobs USING btree (callid);


--
-- Name: idx_calls_sessions_call_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_calls_sessions_call_id ON public.calls_sessions USING btree (callid);


--
-- Name: idx_channel_search_txt; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_channel_search_txt ON public.channels USING gin (to_tsvector('english'::regconfig, (((((name)::text || ' '::text) || (displayname)::text) || ' '::text) || (purpose)::text)));


--
-- Name: idx_channelbookmarks_channelid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_channelbookmarks_channelid ON public.channelbookmarks USING btree (channelid);


--
-- Name: idx_channelbookmarks_delete_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_channelbookmarks_delete_at ON public.channelbookmarks USING btree (deleteat);


--
-- Name: idx_channelbookmarks_update_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_channelbookmarks_update_at ON public.channelbookmarks USING btree (updateat);


--
-- Name: idx_channelmembers_channel_id_scheme_guest_user_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_channelmembers_channel_id_scheme_guest_user_id ON public.channelmembers USING btree (channelid, schemeguest, userid);


--
-- Name: idx_channelmembers_user_id_channel_id_last_viewed_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_channelmembers_user_id_channel_id_last_viewed_at ON public.channelmembers USING btree (userid, channelid, lastviewedat);


--
-- Name: idx_channels_create_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_channels_create_at ON public.channels USING btree (createat);


--
-- Name: idx_channels_delete_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_channels_delete_at ON public.channels USING btree (deleteat);


--
-- Name: idx_channels_displayname_lower; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_channels_displayname_lower ON public.channels USING btree (lower((displayname)::text));


--
-- Name: idx_channels_name_lower; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_channels_name_lower ON public.channels USING btree (lower((name)::text));


--
-- Name: idx_channels_scheme_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_channels_scheme_id ON public.channels USING btree (schemeid);


--
-- Name: idx_channels_team_id_display_name; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_channels_team_id_display_name ON public.channels USING btree (teamid, displayname);


--
-- Name: idx_channels_team_id_type; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_channels_team_id_type ON public.channels USING btree (teamid, type);


--
-- Name: idx_channels_update_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_channels_update_at ON public.channels USING btree (updateat);


--
-- Name: idx_command_create_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_command_create_at ON public.commands USING btree (createat);


--
-- Name: idx_command_delete_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_command_delete_at ON public.commands USING btree (deleteat);


--
-- Name: idx_command_team_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_command_team_id ON public.commands USING btree (teamid);


--
-- Name: idx_command_update_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_command_update_at ON public.commands USING btree (updateat);


--
-- Name: idx_command_webhook_create_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_command_webhook_create_at ON public.commandwebhooks USING btree (createat);


--
-- Name: idx_desktoptokens_token_createat; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_desktoptokens_token_createat ON public.desktoptokens USING btree (token, createat);


--
-- Name: idx_emoji_create_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_emoji_create_at ON public.emoji USING btree (createat);


--
-- Name: idx_emoji_delete_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_emoji_delete_at ON public.emoji USING btree (deleteat);


--
-- Name: idx_emoji_update_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_emoji_update_at ON public.emoji USING btree (updateat);


--
-- Name: idx_fileinfo_channel_id_create_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_fileinfo_channel_id_create_at ON public.fileinfo USING btree (channelid, createat);


--
-- Name: idx_fileinfo_content_txt; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_fileinfo_content_txt ON public.fileinfo USING gin (to_tsvector('english'::regconfig, content));


--
-- Name: idx_fileinfo_create_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_fileinfo_create_at ON public.fileinfo USING btree (createat);


--
-- Name: idx_fileinfo_delete_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_fileinfo_delete_at ON public.fileinfo USING btree (deleteat);


--
-- Name: idx_fileinfo_extension_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_fileinfo_extension_at ON public.fileinfo USING btree (extension);


--
-- Name: idx_fileinfo_name_splitted; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_fileinfo_name_splitted ON public.fileinfo USING gin (to_tsvector('english'::regconfig, translate((name)::text, '.,-'::text, '   '::text)));


--
-- Name: idx_fileinfo_name_txt; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_fileinfo_name_txt ON public.fileinfo USING gin (to_tsvector('english'::regconfig, (name)::text));


--
-- Name: idx_fileinfo_postid_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_fileinfo_postid_at ON public.fileinfo USING btree (postid);


--
-- Name: idx_fileinfo_update_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_fileinfo_update_at ON public.fileinfo USING btree (updateat);


--
-- Name: idx_groupchannels_channelid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_groupchannels_channelid ON public.groupchannels USING btree (channelid);


--
-- Name: idx_groupchannels_schemeadmin; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_groupchannels_schemeadmin ON public.groupchannels USING btree (schemeadmin);


--
-- Name: idx_groupmembers_create_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_groupmembers_create_at ON public.groupmembers USING btree (createat);


--
-- Name: idx_groupteams_schemeadmin; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_groupteams_schemeadmin ON public.groupteams USING btree (schemeadmin);


--
-- Name: idx_groupteams_teamid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_groupteams_teamid ON public.groupteams USING btree (teamid);


--
-- Name: idx_incoming_webhook_create_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_incoming_webhook_create_at ON public.incomingwebhooks USING btree (createat);


--
-- Name: idx_incoming_webhook_delete_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_incoming_webhook_delete_at ON public.incomingwebhooks USING btree (deleteat);


--
-- Name: idx_incoming_webhook_team_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_incoming_webhook_team_id ON public.incomingwebhooks USING btree (teamid);


--
-- Name: idx_incoming_webhook_update_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_incoming_webhook_update_at ON public.incomingwebhooks USING btree (updateat);


--
-- Name: idx_incoming_webhook_user_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_incoming_webhook_user_id ON public.incomingwebhooks USING btree (userid);


--
-- Name: idx_jobs_status_type; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_jobs_status_type ON public.jobs USING btree (status, type);


--
-- Name: idx_jobs_type; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_jobs_type ON public.jobs USING btree (type);


--
-- Name: idx_link_metadata_url_timestamp; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_link_metadata_url_timestamp ON public.linkmetadata USING btree (url, "timestamp");


--
-- Name: idx_notice_views_notice_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_notice_views_notice_id ON public.productnoticeviewstate USING btree (noticeid);


--
-- Name: idx_notice_views_timestamp; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_notice_views_timestamp ON public.productnoticeviewstate USING btree ("timestamp");


--
-- Name: idx_oauthaccessdata_refresh_token; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_oauthaccessdata_refresh_token ON public.oauthaccessdata USING btree (refreshtoken);


--
-- Name: idx_oauthaccessdata_user_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_oauthaccessdata_user_id ON public.oauthaccessdata USING btree (userid);


--
-- Name: idx_oauthapps_creator_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_oauthapps_creator_id ON public.oauthapps USING btree (creatorid);


--
-- Name: idx_outgoing_webhook_create_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_outgoing_webhook_create_at ON public.outgoingwebhooks USING btree (createat);


--
-- Name: idx_outgoing_webhook_delete_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_outgoing_webhook_delete_at ON public.outgoingwebhooks USING btree (deleteat);


--
-- Name: idx_outgoing_webhook_team_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_outgoing_webhook_team_id ON public.outgoingwebhooks USING btree (teamid);


--
-- Name: idx_outgoing_webhook_update_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_outgoing_webhook_update_at ON public.outgoingwebhooks USING btree (updateat);


--
-- Name: idx_outgoingoauthconnections_name; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_outgoingoauthconnections_name ON public.outgoingoauthconnections USING btree (name);


--
-- Name: idx_postreminders_targettime; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_postreminders_targettime ON public.postreminders USING btree (targettime);


--
-- Name: idx_posts_channel_id_delete_at_create_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_posts_channel_id_delete_at_create_at ON public.posts USING btree (channelid, deleteat, createat);


--
-- Name: idx_posts_channel_id_update_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_posts_channel_id_update_at ON public.posts USING btree (channelid, updateat);


--
-- Name: idx_posts_create_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_posts_create_at ON public.posts USING btree (createat);


--
-- Name: idx_posts_create_at_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_posts_create_at_id ON public.posts USING btree (createat, id);


--
-- Name: idx_posts_delete_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_posts_delete_at ON public.posts USING btree (deleteat);


--
-- Name: idx_posts_hashtags_txt; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_posts_hashtags_txt ON public.posts USING gin (to_tsvector('english'::regconfig, (hashtags)::text));


--
-- Name: idx_posts_is_pinned; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_posts_is_pinned ON public.posts USING btree (ispinned);


--
-- Name: idx_posts_message_txt; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_posts_message_txt ON public.posts USING gin (to_tsvector('english'::regconfig, (message)::text));


--
-- Name: idx_posts_original_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_posts_original_id ON public.posts USING btree (originalid);


--
-- Name: idx_posts_root_id_delete_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_posts_root_id_delete_at ON public.posts USING btree (rootid, deleteat);


--
-- Name: idx_posts_update_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_posts_update_at ON public.posts USING btree (updateat);


--
-- Name: idx_posts_user_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_posts_user_id ON public.posts USING btree (userid);


--
-- Name: idx_poststats_userid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_poststats_userid ON public.poststats USING btree (userid);


--
-- Name: idx_preferences_category; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_preferences_category ON public.preferences USING btree (category);


--
-- Name: idx_preferences_name; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_preferences_name ON public.preferences USING btree (name);


--
-- Name: idx_propertyfields_unique; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE UNIQUE INDEX idx_propertyfields_unique ON public.propertyfields USING btree (groupid, targetid, name) WHERE (deleteat = 0);


--
-- Name: idx_propertyvalues_targetid_groupid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_propertyvalues_targetid_groupid ON public.propertyvalues USING btree (targetid, groupid);


--
-- Name: idx_propertyvalues_unique; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE UNIQUE INDEX idx_propertyvalues_unique ON public.propertyvalues USING btree (groupid, targetid, fieldid) WHERE (deleteat = 0);


--
-- Name: idx_publicchannels_delete_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_publicchannels_delete_at ON public.publicchannels USING btree (deleteat);


--
-- Name: idx_publicchannels_displayname_lower; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_publicchannels_displayname_lower ON public.publicchannels USING btree (lower((displayname)::text));


--
-- Name: idx_publicchannels_name_lower; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_publicchannels_name_lower ON public.publicchannels USING btree (lower((name)::text));


--
-- Name: idx_publicchannels_search_txt; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_publicchannels_search_txt ON public.publicchannels USING gin (to_tsvector('english'::regconfig, (((((name)::text || ' '::text) || (displayname)::text) || ' '::text) || (purpose)::text)));


--
-- Name: idx_publicchannels_team_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_publicchannels_team_id ON public.publicchannels USING btree (teamid);


--
-- Name: idx_reactions_channel_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_reactions_channel_id ON public.reactions USING btree (channelid);


--
-- Name: idx_retentionidsfordeletion_tablename; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_retentionidsfordeletion_tablename ON public.retentionidsfordeletion USING btree (tablename);


--
-- Name: idx_retentionpolicies_displayname; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_retentionpolicies_displayname ON public.retentionpolicies USING btree (displayname);


--
-- Name: idx_retentionpolicieschannels_policyid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_retentionpolicieschannels_policyid ON public.retentionpolicieschannels USING btree (policyid);


--
-- Name: idx_retentionpoliciesteams_policyid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_retentionpoliciesteams_policyid ON public.retentionpoliciesteams USING btree (policyid);


--
-- Name: idx_scheduledposts_userid_channel_id_scheduled_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_scheduledposts_userid_channel_id_scheduled_at ON public.scheduledposts USING btree (userid, channelid, scheduledat);


--
-- Name: idx_schemes_channel_admin_role; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_schemes_channel_admin_role ON public.schemes USING btree (defaultchanneladminrole);


--
-- Name: idx_schemes_channel_guest_role; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_schemes_channel_guest_role ON public.schemes USING btree (defaultchannelguestrole);


--
-- Name: idx_schemes_channel_user_role; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_schemes_channel_user_role ON public.schemes USING btree (defaultchanneluserrole);


--
-- Name: idx_sessions_create_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_sessions_create_at ON public.sessions USING btree (createat);


--
-- Name: idx_sessions_expires_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_sessions_expires_at ON public.sessions USING btree (expiresat);


--
-- Name: idx_sessions_last_activity_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_sessions_last_activity_at ON public.sessions USING btree (lastactivityat);


--
-- Name: idx_sessions_token; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_sessions_token ON public.sessions USING btree (token);


--
-- Name: idx_sessions_user_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_sessions_user_id ON public.sessions USING btree (userid);


--
-- Name: idx_sharedchannelusers_remote_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_sharedchannelusers_remote_id ON public.sharedchannelusers USING btree (remoteid);


--
-- Name: idx_sidebarcategories_userid_teamid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_sidebarcategories_userid_teamid ON public.sidebarcategories USING btree (userid, teamid);


--
-- Name: idx_sidebarchannels_categoryid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_sidebarchannels_categoryid ON public.sidebarchannels USING btree (categoryid);


--
-- Name: idx_status_status_dndendtime; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_status_status_dndendtime ON public.status USING btree (status, dndendtime);


--
-- Name: idx_teammembers_createat; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_teammembers_createat ON public.teammembers USING btree (createat);


--
-- Name: idx_teammembers_delete_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_teammembers_delete_at ON public.teammembers USING btree (deleteat);


--
-- Name: idx_teammembers_user_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_teammembers_user_id ON public.teammembers USING btree (userid);


--
-- Name: idx_teams_create_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_teams_create_at ON public.teams USING btree (createat);


--
-- Name: idx_teams_delete_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_teams_delete_at ON public.teams USING btree (deleteat);


--
-- Name: idx_teams_invite_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_teams_invite_id ON public.teams USING btree (inviteid);


--
-- Name: idx_teams_scheme_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_teams_scheme_id ON public.teams USING btree (schemeid);


--
-- Name: idx_teams_update_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_teams_update_at ON public.teams USING btree (updateat);


--
-- Name: idx_thread_memberships_last_update_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_thread_memberships_last_update_at ON public.threadmemberships USING btree (lastupdated);


--
-- Name: idx_thread_memberships_last_view_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_thread_memberships_last_view_at ON public.threadmemberships USING btree (lastviewed);


--
-- Name: idx_thread_memberships_user_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_thread_memberships_user_id ON public.threadmemberships USING btree (userid);


--
-- Name: idx_threads_channel_id_last_reply_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_threads_channel_id_last_reply_at ON public.threads USING btree (channelid, lastreplyat);


--
-- Name: idx_uploadsessions_create_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_uploadsessions_create_at ON public.uploadsessions USING btree (createat);


--
-- Name: idx_uploadsessions_type; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_uploadsessions_type ON public.uploadsessions USING btree (type);


--
-- Name: idx_uploadsessions_user_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_uploadsessions_user_id ON public.uploadsessions USING btree (userid);


--
-- Name: idx_user_access_tokens_user_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_user_access_tokens_user_id ON public.useraccesstokens USING btree (userid);


--
-- Name: idx_usergroups_delete_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_usergroups_delete_at ON public.usergroups USING btree (deleteat);


--
-- Name: idx_usergroups_displayname; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_usergroups_displayname ON public.usergroups USING btree (displayname);


--
-- Name: idx_usergroups_remote_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_usergroups_remote_id ON public.usergroups USING btree (remoteid);


--
-- Name: idx_users_all_no_full_name_txt; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_users_all_no_full_name_txt ON public.users USING gin (to_tsvector('english'::regconfig, (((((username)::text || ' '::text) || (nickname)::text) || ' '::text) || (email)::text)));


--
-- Name: idx_users_all_txt; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_users_all_txt ON public.users USING gin (to_tsvector('english'::regconfig, (((((((((username)::text || ' '::text) || (firstname)::text) || ' '::text) || (lastname)::text) || ' '::text) || (nickname)::text) || ' '::text) || (email)::text)));


--
-- Name: idx_users_create_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_users_create_at ON public.users USING btree (createat);


--
-- Name: idx_users_delete_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_users_delete_at ON public.users USING btree (deleteat);


--
-- Name: idx_users_email_lower_textpattern; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_users_email_lower_textpattern ON public.users USING btree (lower((email)::text) text_pattern_ops);


--
-- Name: idx_users_firstname_lower_textpattern; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_users_firstname_lower_textpattern ON public.users USING btree (lower((firstname)::text) text_pattern_ops);


--
-- Name: idx_users_lastname_lower_textpattern; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_users_lastname_lower_textpattern ON public.users USING btree (lower((lastname)::text) text_pattern_ops);


--
-- Name: idx_users_names_no_full_name_txt; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_users_names_no_full_name_txt ON public.users USING gin (to_tsvector('english'::regconfig, (((username)::text || ' '::text) || (nickname)::text)));


--
-- Name: idx_users_names_txt; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_users_names_txt ON public.users USING gin (to_tsvector('english'::regconfig, (((((((username)::text || ' '::text) || (firstname)::text) || ' '::text) || (lastname)::text) || ' '::text) || (nickname)::text)));


--
-- Name: idx_users_nickname_lower_textpattern; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_users_nickname_lower_textpattern ON public.users USING btree (lower((nickname)::text) text_pattern_ops);


--
-- Name: idx_users_update_at; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_users_update_at ON public.users USING btree (updateat);


--
-- Name: idx_users_username_lower_textpattern; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX idx_users_username_lower_textpattern ON public.users USING btree (lower((username)::text) text_pattern_ops);


--
-- Name: ir_category_item_categoryid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_category_item_categoryid ON public.ir_category_item USING btree (categoryid);


--
-- Name: ir_category_teamid_userid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_category_teamid_userid ON public.ir_category USING btree (teamid, userid);


--
-- Name: ir_channelaction_channelid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_channelaction_channelid ON public.ir_channelaction USING btree (channelid);


--
-- Name: ir_incident_channelid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_incident_channelid ON public.ir_incident USING btree (channelid);


--
-- Name: ir_incident_teamid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_incident_teamid ON public.ir_incident USING btree (teamid);


--
-- Name: ir_incident_teamid_commanderuserid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_incident_teamid_commanderuserid ON public.ir_incident USING btree (teamid, commanderuserid);


--
-- Name: ir_metric_incidentid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_metric_incidentid ON public.ir_metric USING btree (incidentid);


--
-- Name: ir_metric_metricconfigid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_metric_metricconfigid ON public.ir_metric USING btree (metricconfigid);


--
-- Name: ir_metricconfig_playbookid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_metricconfig_playbookid ON public.ir_metricconfig USING btree (playbookid);


--
-- Name: ir_playbook_teamid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_playbook_teamid ON public.ir_playbook USING btree (teamid);


--
-- Name: ir_playbook_updateat; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_playbook_updateat ON public.ir_playbook USING btree (updateat);


--
-- Name: ir_playbookmember_memberid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_playbookmember_memberid ON public.ir_playbookmember USING btree (memberid);


--
-- Name: ir_playbookmember_playbookid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_playbookmember_playbookid ON public.ir_playbookmember USING btree (playbookid);


--
-- Name: ir_run_participants_incidentid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_run_participants_incidentid ON public.ir_run_participants USING btree (incidentid);


--
-- Name: ir_run_participants_userid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_run_participants_userid ON public.ir_run_participants USING btree (userid);


--
-- Name: ir_statusposts_incidentid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_statusposts_incidentid ON public.ir_statusposts USING btree (incidentid);


--
-- Name: ir_statusposts_postid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_statusposts_postid ON public.ir_statusposts USING btree (postid);


--
-- Name: ir_timelineevent_id; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_timelineevent_id ON public.ir_timelineevent USING btree (id);


--
-- Name: ir_timelineevent_incidentid; Type: INDEX; Schema: public; Owner: mattermost_user
--

CREATE INDEX ir_timelineevent_incidentid ON public.ir_timelineevent USING btree (incidentid);


--
-- Name: retentionpolicieschannels fk_retentionpolicieschannels_retentionpolicies; Type: FK CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.retentionpolicieschannels
    ADD CONSTRAINT fk_retentionpolicieschannels_retentionpolicies FOREIGN KEY (policyid) REFERENCES public.retentionpolicies(id) ON DELETE CASCADE;


--
-- Name: retentionpoliciesteams fk_retentionpoliciesteams_retentionpolicies; Type: FK CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.retentionpoliciesteams
    ADD CONSTRAINT fk_retentionpoliciesteams_retentionpolicies FOREIGN KEY (policyid) REFERENCES public.retentionpolicies(id) ON DELETE CASCADE;


--
-- Name: ir_category_item ir_category_item_categoryid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_category_item
    ADD CONSTRAINT ir_category_item_categoryid_fkey FOREIGN KEY (categoryid) REFERENCES public.ir_category(id);


--
-- Name: ir_metric ir_metric_incidentid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_metric
    ADD CONSTRAINT ir_metric_incidentid_fkey FOREIGN KEY (incidentid) REFERENCES public.ir_incident(id);


--
-- Name: ir_metric ir_metric_metricconfigid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_metric
    ADD CONSTRAINT ir_metric_metricconfigid_fkey FOREIGN KEY (metricconfigid) REFERENCES public.ir_metricconfig(id);


--
-- Name: ir_metricconfig ir_metricconfig_playbookid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_metricconfig
    ADD CONSTRAINT ir_metricconfig_playbookid_fkey FOREIGN KEY (playbookid) REFERENCES public.ir_playbook(id);


--
-- Name: ir_playbookautofollow ir_playbookautofollow_playbookid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_playbookautofollow
    ADD CONSTRAINT ir_playbookautofollow_playbookid_fkey FOREIGN KEY (playbookid) REFERENCES public.ir_playbook(id);


--
-- Name: ir_playbookmember ir_playbookmember_playbookid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_playbookmember
    ADD CONSTRAINT ir_playbookmember_playbookid_fkey FOREIGN KEY (playbookid) REFERENCES public.ir_playbook(id);


--
-- Name: ir_run_participants ir_run_participants_incidentid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_run_participants
    ADD CONSTRAINT ir_run_participants_incidentid_fkey FOREIGN KEY (incidentid) REFERENCES public.ir_incident(id);


--
-- Name: ir_statusposts ir_statusposts_incidentid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_statusposts
    ADD CONSTRAINT ir_statusposts_incidentid_fkey FOREIGN KEY (incidentid) REFERENCES public.ir_incident(id);


--
-- Name: ir_timelineevent ir_timelineevent_incidentid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.ir_timelineevent
    ADD CONSTRAINT ir_timelineevent_incidentid_fkey FOREIGN KEY (incidentid) REFERENCES public.ir_incident(id);


--
-- Name: llm_postmeta llm_postmeta_rootpostid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mattermost_user
--

ALTER TABLE ONLY public.llm_postmeta
    ADD CONSTRAINT llm_postmeta_rootpostid_fkey FOREIGN KEY (rootpostid) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: poststats; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: mattermost_user
--

REFRESH MATERIALIZED VIEW public.poststats;


--
-- PostgreSQL database dump complete
--

\unrestrict h4IlctqZaQddMJnyEOvhp8K7mdVld0BfVfmihj9hDQ9aSyMgBZ26SC8forwl60U

