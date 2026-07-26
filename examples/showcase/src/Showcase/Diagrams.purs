module Showcase.Diagrams where

import Prelude

import Dagre.Graph (NodeOptions, RankDir(..))
import Data.Array (filter, head)
import Data.Maybe (Maybe)
import Data.String (joinWith)

type NodeInfo = { id :: String, label :: String, detail :: String }

type NodeStyle = { id :: String, fill :: String, stroke :: String, subtitle :: String }

type DagreCluster = { label :: String, nodes :: Array String }

type DiagramSpec =
  { id :: String
  , title :: String
  , category :: String
  , description :: String
  , dagreNodes :: Array NodeOptions
  , dagreEdges :: Array { source :: String, target :: String, label :: String, dashed :: Boolean }
  , dagreRankDir :: RankDir
  , dotSource :: String
  , nodeInfo :: Array NodeInfo
  , dagreStyles :: Array NodeStyle
  , dagreClusters :: Array DagreCluster
  }

type Category = { name :: String, ids :: Array String }

mkNode :: String -> String -> NodeOptions
mkNode id label = { id, width: 160.0, height: 58.0, label }

mkInfo :: String -> String -> String -> NodeInfo
mkInfo id label detail = { id, label, detail }

e :: String -> String -> { source :: String, target :: String, label :: String, dashed :: Boolean }
e source target = { source, target, label: "", dashed: false }

el
  :: String
  -> String
  -> String
  -> { source :: String, target :: String, label :: String, dashed :: Boolean }
el source target label = { source, target, label, dashed: false }

ed
  :: String
  -> String
  -> String
  -> { source :: String, target :: String, label :: String, dashed :: Boolean }
ed source target label = { source, target, label, dashed: true }

cluster :: String -> Array String -> DagreCluster
cluster label nodes = { label, nodes }

sEntry :: String -> String -> NodeStyle
sEntry id subtitle = { id, fill: "#bbdefb", stroke: "#1976d2", subtitle }

sProcess :: String -> String -> NodeStyle
sProcess id subtitle = { id, fill: "#ffe0b2", stroke: "#f57c00", subtitle }

sCache :: String -> String -> NodeStyle
sCache id subtitle = { id, fill: "#c8e6c9", stroke: "#388e3c", subtitle }

sDist :: String -> String -> NodeStyle
sDist id subtitle = { id, fill: "#f8bbd0", stroke: "#c2185b", subtitle }

sAdvanced :: String -> String -> NodeStyle
sAdvanced id subtitle = { id, fill: "#e1bee7", stroke: "#7b1fa2", subtitle }

scaleDiagram :: DiagramSpec
scaleDiagram =
  { id: "scale"
  , title: "Scale From Zero to Millions"
  , category: "Architecture"
  , description: "Evolution from a single server to a globally distributed system."
  , dagreNodes:
      [ mkNode "single" "1. Single Server"
      , mkNode "webdb" "2. Web + DB Split"
      , mkNode "lb" "3. Load Balancer"
      , mkNode "replica" "4. DB Replication"
      , mkNode "cache" "5. Cache Layer"
      , mkNode "cdn" "6. CDN"
      , mkNode "stateless" "7. Stateless Web"
      , mkNode "multiDC" "8. Multi-DC"
      , mkNode "mq" "9. Message Queue"
      , mkNode "shard" "10. DB Sharding"
      ]
  , dagreEdges:
      [ e "single" "webdb"
      , e "webdb" "lb"
      , e "lb" "replica"
      , e "replica" "cache"
      , e "cache" "cdn"
      , e "cdn" "stateless"
      , e "stateless" "multiDC"
      , e "multiDC" "mq"
      , e "mq" "shard"
      ]
  , dagreRankDir: TopBottom
  , dotSource: joinWith "\n"
      [ "digraph scale {"
      , "  rankdir=TB; bgcolor=\"transparent\";"
      , "  node [shape=box, style=\"rounded,filled\", fontname=\"sans-serif\", fontsize=11];"
      , "  edge [color=\"#666\", penwidth=1.5, arrowsize=0.8];"
      , "  single [label=\"1. Single Server\\n(Web + DB + App)\", fillcolor=\"#bbdefb\"];"
      , "  webdb [label=\"2. Web + DB Split\\n(Separate Servers)\", fillcolor=\"#bbdefb\"];"
      , "  lb [label=\"3. Load Balancer\\n(Traffic Distribution)\", fillcolor=\"#ffe0b2\"];"
      , "  replica [label=\"4. DB Replication\\n(Master + Replicas)\", fillcolor=\"#ffe0b2\"];"
      , "  cache [label=\"5. Cache Layer\\n(Redis / Memcached)\", fillcolor=\"#c8e6c9\"];"
      , "  cdn [label=\"6. CDN\\n(Edge Content Delivery)\", fillcolor=\"#c8e6c9\"];"
      , "  stateless [label=\"7. Stateless Web\\n(Auto-Scaling)\", fillcolor=\"#f8bbd0\"];"
      , "  multiDC [label=\"8. Multi-Data Center\\n(Geo-Distribution)\", fillcolor=\"#f8bbd0\"];"
      , "  mq [label=\"9. Message Queue\\n(Async Decoupling)\", fillcolor=\"#e1bee7\"];"
      , "  shard [label=\"10. DB Sharding\\n(Horizontal Partitioning)\", fillcolor=\"#e1bee7\"];"
      , "  single -> webdb -> lb -> replica -> cache -> cdn -> stateless -> multiDC -> mq -> shard;"
      , "}"
      ]
  , nodeInfo:
      [ mkInfo "single" "Single Server"
          "One server handles everything: web server, application logic, and database on a single machine."
      , mkInfo "webdb" "Web + DB Split"
          "Separate the database onto its own server for resource isolation and independent scaling."
      , mkInfo "lb" "Load Balancer"
          "Distribute traffic across multiple web servers, enabling horizontal scaling."
      , mkInfo "replica" "DB Replication"
          "Master for writes, read replicas for read queries. Improves read throughput."
      , mkInfo "cache" "Cache Layer"
          "Redis or Memcached to cache frequent query results and reduce database load."
      , mkInfo "cdn" "CDN"
          "Content Delivery Network serves static assets from edge locations close to users."
      , mkInfo "stateless" "Stateless Web"
          "Move session state to shared store, enabling auto-scaling and easy replacement."
      , mkInfo "multiDC" "Multi-Data Center"
          "Deploy across multiple data centers for geo-distribution and disaster recovery."
      , mkInfo "mq" "Message Queue"
          "Async message queues (Kafka, RabbitMQ) for decoupling services and better resilience."
      , mkInfo "shard" "DB Sharding"
          "Partition the database horizontally across multiple servers to scale writes."
      ]
  , dagreStyles:
      [ sEntry "single" "Web + DB + App"
      , sEntry "webdb" "Separate Servers"
      , sProcess "lb" "Traffic Distribution"
      , sProcess "replica" "Master + Replicas"
      , sCache "cache" "Redis / Memcached"
      , sCache "cdn" "Edge Content Delivery"
      , sDist "stateless" "Auto-Scaling"
      , sDist "multiDC" "Geo-Distribution"
      , sAdvanced "mq" "Async Decoupling"
      , sAdvanced "shard" "Horizontal Partitioning"
      ]
  , dagreClusters: []
  }

blueprintDiagram :: DiagramSpec
blueprintDiagram =
  { id: "blueprint"
  , title: "System Design Blueprint"
  , category: "Architecture"
  , description:
      "Complete production architecture: DNS, CDN, load balancer, stateless web tier, cache, message queue, DB replication."
  , dagreNodes:
      [ mkNode "dns" "DNS"
      , mkNode "cdn" "CDN"
      , mkNode "lb" "Load Balancer"
      , mkNode "web1" "Web Server 1"
      , mkNode "web2" "Web Server 2"
      , mkNode "web3" "Web Server N"
      , mkNode "cache" "Redis Cache"
      , mkNode "queue" "Message Queue"
      , mkNode "worker" "Worker"
      , mkNode "master" "DB Master"
      , mkNode "slave" "DB Replica"
      ]
  , dagreEdges:
      [ e "dns" "lb"
      , el "dns" "cdn" "static"
      , e "lb" "web1"
      , e "lb" "web2"
      , e "lb" "web3"
      , e "web1" "cache"
      , e "web1" "queue"
      , e "web2" "cache"
      , e "web2" "queue"
      , e "web3" "cache"
      , e "web3" "queue"
      , el "cache" "master" "miss"
      , el "master" "slave" "replication"
      , el "queue" "worker" "consume"
      , el "worker" "master" "write"
      ]
  , dagreRankDir: TopBottom
  , dotSource: joinWith "\n"
      [ "digraph blueprint {"
      , "  rankdir=TB; bgcolor=\"transparent\";"
      , "  node [shape=box, style=\"rounded,filled\", fontname=\"sans-serif\", fontsize=11];"
      , "  edge [color=\"#666\", penwidth=1.5, arrowsize=0.8];"
      , "  subgraph cluster_edge { label=\"Edge\"; style=rounded; color=\"#e0e0e0\";"
      , "    dns [label=\"DNS\\n(Route 53)\", fillcolor=\"#bbdefb\"];"
      , "    cdn [label=\"CDN\\n(CloudFront)\", fillcolor=\"#c8e6c9\"];"
      , "    lb [label=\"Load Balancer\\n(ALB)\", fillcolor=\"#ffe0b2\"];"
      , "  }"
      , "  subgraph cluster_app { label=\"Application Tier\"; style=rounded; color=\"#e0e0e0\";"
      , "    web1 [label=\"Web Server 1\\n(stateless)\", fillcolor=\"#ffe0b2\"];"
      , "    web2 [label=\"Web Server 2\\n(stateless)\", fillcolor=\"#ffe0b2\"];"
      , "    web3 [label=\"Web Server N\\n(auto-scaled)\", fillcolor=\"#ffe0b2\"];"
      , "  }"
      , "  subgraph cluster_async { label=\"Async\"; style=rounded; color=\"#e0e0e0\";"
      , "    queue [label=\"Message Queue\\n(Kafka)\", fillcolor=\"#e1bee7\"];"
      , "    worker [label=\"Worker\\n(Background Jobs)\", fillcolor=\"#e1bee7\"];"
      , "  }"
      , "  subgraph cluster_data { label=\"Data Tier\"; style=rounded; color=\"#e0e0e0\";"
      , "    cache [label=\"Cache\\n(Redis)\", fillcolor=\"#c8e6c9\"];"
      , "    master [label=\"DB Master\\n(writes)\", fillcolor=\"#f8bbd0\"];"
      , "    slave [label=\"DB Replica\\n(reads)\", fillcolor=\"#f8bbd0\"];"
      , "  }"
      , "  dns -> lb; dns -> cdn [label=\"static\"];"
      , "  lb -> web1; lb -> web2; lb -> web3;"
      , "  web1 -> cache; web1 -> queue;"
      , "  web2 -> cache; web2 -> queue;"
      , "  web3 -> cache; web3 -> queue;"
      , "  cache -> master [label=\"miss\"];"
      , "  master -> slave [label=\"replication\"];"
      , "  queue -> worker [label=\"consume\"];"
      , "  worker -> master [label=\"write\"];"
      , "}"
      ]
  , nodeInfo:
      [ mkInfo "dns" "DNS (Route 53)"
          "Translates domain names to IP addresses. Routes traffic to the nearest load balancer or CDN."
      , mkInfo "cdn" "CDN (CloudFront)"
          "Caches static assets at edge locations worldwide, reducing latency for end users."
      , mkInfo "lb" "Load Balancer (ALB)"
          "Distributes incoming traffic across multiple web servers with health checks."
      , mkInfo "web1" "Web Server 1"
          "Stateless application server. Can be replaced or scaled independently."
      , mkInfo "web2" "Web Server 2"
          "Stateless application server. Identical to web1, shares the load."
      , mkInfo "web3" "Web Server N"
          "Auto-scaled instance. Fleet grows or shrinks based on metrics."
      , mkInfo "cache" "Redis Cache"
          "In-memory key-value store for caching query results and session data."
      , mkInfo "queue" "Message Queue (Kafka)"
          "Durable message broker for asynchronous task processing."
      , mkInfo "worker" "Worker" "Background job processor that consumes messages from the queue."
      , mkInfo "master" "DB Master (writes)"
          "Primary database instance handling all write operations."
      , mkInfo "slave" "DB Replica (reads)" "Read replica mirroring the master via replication."
      ]
  , dagreStyles:
      [ sEntry "dns" "Route 53"
      , sCache "cdn" "CloudFront"
      , sProcess "lb" "ALB"
      , sProcess "web1" "stateless"
      , sProcess "web2" "stateless"
      , sProcess "web3" "auto-scaled"
      , sAdvanced "queue" "Kafka"
      , sAdvanced "worker" "Background Jobs"
      , sCache "cache" "Redis"
      , sDist "master" "writes"
      , sDist "slave" "reads"
      ]
  , dagreClusters:
      [ cluster "Edge" [ "dns", "cdn", "lb" ]
      , cluster "Application Tier" [ "web1", "web2", "web3" ]
      , cluster "Async" [ "queue", "worker" ]
      , cluster "Data Tier" [ "cache", "master", "slave" ]
      ]
  }

cacheDiagram :: DiagramSpec
cacheDiagram =
  { id: "cache"
  , title: "Cache Layers"
  , category: "Architecture"
  , description:
      "Multiple caching layers from browser to database, each intercepting requests at a different level."
  , dagreNodes:
      [ mkNode "browser" "Browser Cache"
      , mkNode "cdn" "CDN Cache"
      , mkNode "lb" "Load Balancer"
      , mkNode "web" "Web Server"
      , mkNode "redis" "Redis Cache"
      , mkNode "db" "Database"
      ]
  , dagreEdges:
      [ el "browser" "cdn" "miss"
      , el "cdn" "lb" "miss"
      , e "lb" "web"
      , el "web" "redis" "lookup"
      , el "redis" "db" "miss"
      , ed "web" "db" "write-through"
      ]
  , dagreRankDir: LeftRight
  , dotSource: joinWith "\n"
      [ "digraph cache {"
      , "  rankdir=LR; bgcolor=\"transparent\";"
      , "  node [shape=box, style=\"rounded,filled\", fontname=\"sans-serif\", fontsize=11];"
      , "  edge [color=\"#666\", penwidth=1.5, arrowsize=0.8];"
      , "  subgraph cluster_edge { label=\"Edge Layer\"; style=rounded; color=\"#e0e0e0\";"
      , "    browser [label=\"Browser\\nCache\", fillcolor=\"#bbdefb\"];"
      , "    cdn [label=\"CDN\\n(Edge Cache)\", fillcolor=\"#bbdefb\"];"
      , "  }"
      , "  subgraph cluster_app { label=\"Application\"; style=rounded; color=\"#e0e0e0\";"
      , "    lb [label=\"Load\\nBalancer\", fillcolor=\"#ffe0b2\"];"
      , "    web [label=\"Web\\nServer\", fillcolor=\"#ffe0b2\"];"
      , "  }"
      , "  subgraph cluster_data { label=\"Data\"; style=rounded; color=\"#e0e0e0\";"
      , "    redis [label=\"Redis\\n(Distributed Cache)\", fillcolor=\"#c8e6c9\"];"
      , "    db [label=\"Database\\n(PostgreSQL)\", fillcolor=\"#f8bbd0\"];"
      , "  }"
      , "  browser -> cdn [label=\"miss\"];"
      , "  cdn -> lb [label=\"miss\"];"
      , "  lb -> web;"
      , "  web -> redis [label=\"lookup\"];"
      , "  redis -> db [label=\"miss\"];"
      , "  web -> db [label=\"write-through\", style=dashed, color=\"#ef5350\"];"
      , "}"
      ]
  , nodeInfo:
      [ mkInfo "browser" "Browser Cache"
          "HTTP cache in the user's browser. Controlled by Cache-Control, ETag, and Last-Modified headers."
      , mkInfo "cdn" "CDN (Edge Cache)"
          "Caches responses at edge POPs. Serves cached content without hitting the origin."
      , mkInfo "lb" "Load Balancer"
          "May cache responses (Nginx proxy_cache). Also terminates SSL and performs health checks."
      , mkInfo "web" "Web Server"
          "Application-level cache (in-process). Caches rendered templates and computed results."
      , mkInfo "redis" "Redis (Distributed Cache)"
          "Shared in-memory cache across all web servers. Stores session data and query results."
      , mkInfo "db" "Database (PostgreSQL)"
          "Source of truth. Only reached on cache misses. Uses internal buffer pool for disk pages."
      ]
  , dagreStyles:
      [ sEntry "browser" "Cache"
      , sEntry "cdn" "Edge Cache"
      , sProcess "lb" "Balancer"
      , sProcess "web" "Server"
      , sCache "redis" "Distributed Cache"
      , sDist "db" "PostgreSQL"
      ]
  , dagreClusters:
      [ cluster "Edge Layer" [ "browser", "cdn" ]
      , cluster "Application" [ "lb", "web" ]
      , cluster "Data" [ "redis", "db" ]
      ]
  }

cicdDiagram :: DiagramSpec
cicdDiagram =
  { id: "cicd"
  , title: "CI/CD Pipeline"
  , category: "Pipeline"
  , description: "From developer commit to production deployment with automated rollback."
  , dagreNodes:
      [ mkNode "dev" "Developer"
      , mkNode "push" "Push to Git"
      , mkNode "build" "Build"
      , mkNode "unittest" "Unit Tests"
      , mkNode "integration" "Integration Tests"
      , mkNode "staging" "Staging Deploy"
      , mkNode "e2e" "E2E Tests"
      , mkNode "prod" "Production Deploy"
      , mkNode "monitor" "Monitor & Alert"
      ]
  , dagreEdges:
      [ e "dev" "push"
      , e "push" "build"
      , e "build" "unittest"
      , e "unittest" "integration"
      , e "integration" "staging"
      , e "staging" "e2e"
      , e "e2e" "prod"
      , e "prod" "monitor"
      , ed "prod" "build" "rollback"
      ]
  , dagreRankDir: LeftRight
  , dotSource: joinWith "\n"
      [ "digraph cicd {"
      , "  rankdir=LR; bgcolor=\"transparent\";"
      , "  node [shape=box, style=\"rounded,filled\", fontname=\"sans-serif\", fontsize=11];"
      , "  edge [color=\"#666\", penwidth=1.5, arrowsize=0.8];"
      , "  subgraph cluster_dev { label=\"Development\"; style=rounded; color=\"#e0e0e0\";"
      , "    dev [label=\"Developer\\nCommit\", fillcolor=\"#bbdefb\"];"
      , "    push [label=\"Push to\\nGit Repo\", fillcolor=\"#bbdefb\"];"
      , "  }"
      , "  subgraph cluster_ci { label=\"CI Pipeline\"; style=rounded; color=\"#e0e0e0\";"
      , "    build [label=\"Build\\n(Compile)\", fillcolor=\"#ffe0b2\"];"
      , "    unittest [label=\"Unit Tests\", fillcolor=\"#ffe0b2\"];"
      , "    integration [label=\"Integration\\nTests\", fillcolor=\"#ffe0b2\"];"
      , "  }"
      , "  subgraph cluster_cd { label=\"CD Pipeline\"; style=rounded; color=\"#e0e0e0\";"
      , "    staging [label=\"Deploy to\\nStaging\", fillcolor=\"#c8e6c9\"];"
      , "    e2e [label=\"E2E Tests\", fillcolor=\"#c8e6c9\"];"
      , "    prod [label=\"Deploy to\\nProduction\", fillcolor=\"#f8bbd0\"];"
      , "    monitor [label=\"Monitor &\\nAlert\", fillcolor=\"#e1bee7\"];"
      , "  }"
      , "  dev -> push -> build -> unittest -> integration;"
      , "  integration -> staging -> e2e -> prod -> monitor;"
      , "  prod -> build [label=\"rollback\", style=dashed, color=\"#ef5350\", fontcolor=\"#ef5350\", fontsize=9];"
      , "}"
      ]
  , nodeInfo:
      [ mkInfo "dev" "Developer Commit"
          "A developer writes code and commits it to a local branch. Entry point of the pipeline."
      , mkInfo "push" "Push to Git Repo"
          "The commit is pushed to a remote repository, triggering a webhook that starts CI."
      , mkInfo "build" "Build (Compile)"
          "CI compiles the code, resolves dependencies, and produces a build artifact."
      , mkInfo "unittest" "Unit Tests"
          "Automated unit tests against the build artifact. Tests individual functions in isolation."
      , mkInfo "integration" "Integration Tests"
          "Verify modules work together. May use a test database and mock external services."
      , mkInfo "staging" "Deploy to Staging"
          "Build artifact deployed to a staging environment mirroring production."
      , mkInfo "e2e" "E2E Tests"
          "End-to-end tests simulate real user flows (Playwright, Selenium, Cypress)."
      , mkInfo "prod" "Deploy to Production"
          "Verified artifact deployed to production via blue-green or canary strategy."
      , mkInfo "monitor" "Monitor & Alert"
          "Post-deployment monitoring. Alerts trigger rollback if error rates spike."
      ]
  , dagreStyles:
      [ sEntry "dev" "Commit"
      , sEntry "push" "Git Repo"
      , sProcess "build" "Compile"
      , sProcess "unittest" ""
      , sProcess "integration" "Tests"
      , sCache "staging" "Staging"
      , sCache "e2e" ""
      , sDist "prod" "Production"
      , sAdvanced "monitor" "Alert"
      ]
  , dagreClusters:
      [ cluster "Development" [ "dev", "push" ]
      , cluster "CI Pipeline" [ "build", "unittest", "integration" ]
      , cluster "CD Pipeline" [ "staging", "e2e", "prod", "monitor" ]
      ]
  }

youtubeDiagram :: DiagramSpec
youtubeDiagram =
  { id: "youtube"
  , title: "YouTube Architecture"
  , category: "Pipeline"
  , description:
      "Video upload pipeline: transcoding, metadata storage, CDN distribution, and playback."
  , dagreNodes:
      [ mkNode "upload" "Video Upload"
      , mkNode "processing" "Processing"
      , mkNode "transcode" "Transcode"
      , mkNode "metadata" "Metadata DB"
      , mkNode "storage" "Object Storage"
      , mkNode "cdn" "CDN"
      , mkNode "player" "Video Player"
      ]
  , dagreEdges:
      [ e "upload" "processing"
      , e "processing" "transcode"
      , e "processing" "metadata"
      , e "transcode" "storage"
      , e "storage" "cdn"
      , e "cdn" "player"
      , ed "metadata" "player" "metadata"
      ]
  , dagreRankDir: LeftRight
  , dotSource: joinWith "\n"
      [ "digraph youtube {"
      , "  rankdir=LR; bgcolor=\"transparent\";"
      , "  node [shape=box, style=\"rounded,filled\", fontname=\"sans-serif\", fontsize=11];"
      , "  edge [color=\"#666\", penwidth=1.5, arrowsize=0.8];"
      , "  subgraph cluster_upload { label=\"Upload\"; style=rounded; color=\"#e0e0e0\";"
      , "    upload [label=\"Video\\nUpload\", fillcolor=\"#bbdefb\"];"
      , "    processing [label=\"Processing\\n& Validation\", fillcolor=\"#ffe0b2\"];"
      , "  }"
      , "  subgraph cluster_transcode { label=\"Transcoding\"; style=rounded; color=\"#e0e0e0\";"
      , "    transcode [label=\"Transcode\\n(240p-4K)\", fillcolor=\"#ffe0b2\"];"
      , "  }"
      , "  subgraph cluster_storage { label=\"Storage & Delivery\"; style=rounded; color=\"#e0e0e0\";"
      , "    metadata [label=\"Metadata DB\\n(Cassandra)\", fillcolor=\"#c8e6c9\"];"
      , "    storage [label=\"Object Storage\\n(S3 / GCS)\", fillcolor=\"#c8e6c9\"];"
      , "    cdn [label=\"CDN\\n(Edge Nodes)\", fillcolor=\"#c8e6c9\"];"
      , "  }"
      , "  player [label=\"Video Player\\n(Web / Mobile / TV)\", fillcolor=\"#f8bbd0\"];"
      , "  upload -> processing;"
      , "  processing -> transcode;"
      , "  processing -> metadata;"
      , "  transcode -> storage;"
      , "  storage -> cdn;"
      , "  cdn -> player;"
      , "  metadata -> player [label=\"metadata\", style=dashed];"
      , "}"
      ]
  , nodeInfo:
      [ mkInfo "upload" "Video Upload"
          "User uploads a video file via HTTP. Large files use resumable uploads with chunked transfer."
      , mkInfo "processing" "Processing & Validation"
          "Validate file format, extract metadata (duration, codec, resolution), generate thumbnails."
      , mkInfo "transcode" "Transcode (240p-4K)"
          "Transcode the video into multiple resolutions and bitrates using ffmpeg or cloud transcoding."
      , mkInfo "metadata" "Metadata DB (Cassandra)"
          "Store video metadata: title, description, tags, view count. Wide-column store for scale."
      , mkInfo "storage" "Object Storage (S3/GCS)"
          "Store transcoded video segments and original file in object storage (S3, GCS)."
      , mkInfo "cdn" "CDN (Edge Nodes)"
          "Cache video segments at edge locations worldwide. Stream from the nearest POP to the user."
      , mkInfo "player" "Video Player"
          "Web, mobile, or TV app player. Uses adaptive bitrate streaming (HLS/DASH) over CDN."
      ]
  , dagreStyles:
      [ sEntry "upload" "Upload"
      , sProcess "processing" "& Validation"
      , sProcess "transcode" "240p-4K"
      , sCache "metadata" "Cassandra"
      , sCache "storage" "S3 / GCS"
      , sCache "cdn" "Edge Nodes"
      , sDist "player" "Web / Mobile / TV"
      ]
  , dagreClusters:
      [ cluster "Upload" [ "upload", "processing" ]
      , cluster "Transcoding" [ "transcode" ]
      , cluster "Storage & Delivery" [ "metadata", "storage", "cdn" ]
      ]
  }

kafkaDiagram :: DiagramSpec
kafkaDiagram =
  { id: "kafka"
  , title: "Kafka Zero-Copy"
  , category: "Pipeline"
  , description:
      "Zero-copy data path: producer writes to disk, sendfile() transfers directly from OS cache to socket."
  , dagreNodes:
      [ mkNode "producer" "Producer"
      , mkNode "disk" "Disk (Log)"
      , mkNode "oscache" "OS Page Cache"
      , mkNode "socket" "Socket"
      , mkNode "consumer" "Consumer"
      ]
  , dagreEdges:
      [ el "producer" "disk" "1. write to log"
      , el "disk" "oscache" "2. kernel read"
      , el "oscache" "socket" "3. zero-copy transfer"
      , el "socket" "consumer" "4. network delivery"
      ]
  , dagreRankDir: LeftRight
  , dotSource: joinWith "\n"
      [ "digraph kafka {"
      , "  rankdir=LR; bgcolor=\"transparent\";"
      , "  node [shape=box, style=\"rounded,filled\", fontname=\"sans-serif\", fontsize=11];"
      , "  edge [color=\"#666\", penwidth=1.5, arrowsize=0.8];"
      , "  producer [label=\"Producer\\n(write())\", fillcolor=\"#bbdefb\"];"
      , "  disk [label=\"Disk\\n(Kafka Log)\", shape=cylinder, fillcolor=\"#ffe0b2\"];"
      , "  oscache [label=\"OS Page Cache\\n(sendfile())\", fillcolor=\"#c8e6c9\"];"
      , "  socket [label=\"Socket\\n(network)\", fillcolor=\"#f8bbd0\"];"
      , "  consumer [label=\"Consumer\\n(read())\", fillcolor=\"#e1bee7\"];"
      , "  producer -> disk [label=\"1. write to log\"];"
      , "  disk -> oscache [label=\"2. kernel read\"];"
      , "  oscache -> socket [label=\"3. zero-copy transfer\"];"
      , "  socket -> consumer [label=\"4. network delivery\"];"
      , "}"
      ]
  , nodeInfo:
      [ mkInfo "producer" "Producer (write())"
          "Kafka producer writes messages to the topic partition. Messages are appended to the segment log file."
      , mkInfo "disk" "Disk (Kafka Log)"
          "Messages are persisted to disk as an append-only log. Kafka relies on OS page cache rather than application-level caching."
      , mkInfo "oscache" "OS Page Cache (sendfile())"
          "The kernel keeps recently read file pages in memory. sendfile() transfers data directly from here to the socket buffer."
      , mkInfo "socket" "Socket (network)"
          "Network socket buffer. With zero-copy, data goes from page cache to socket without entering user space."
      , mkInfo "consumer" "Consumer (read())"
          "Kafka consumer reads messages from the socket. No data copy occurs in the broker's user space."
      ]
  , dagreStyles:
      [ sEntry "producer" "write()"
      , sProcess "disk" "Kafka Log"
      , sCache "oscache" "sendfile()"
      , sDist "socket" "network"
      , sAdvanced "consumer" "read()"
      ]
  , dagreClusters: []
  }

oauthDiagram :: DiagramSpec
oauthDiagram =
  { id: "oauth"
  , title: "OAuth 2.0 Flow"
  , category: "Auth & Data"
  , description:
      "Authorization code flow: client obtains an access token via the authorization server to access protected resources."
  , dagreNodes:
      [ mkNode "user" "Resource Owner"
      , mkNode "client" "Client (App)"
      , mkNode "auth" "Auth Server"
      , mkNode "resource" "Resource Server"
      , mkNode "token" "Access Token"
      , mkNode "refresh" "Refresh Token"
      ]
  , dagreEdges:
      [ el "user" "client" "1. Request"
      , el "client" "auth" "2. Auth Request"
      , el "auth" "user" "3. User Grants"
      , el "user" "auth" "4. Consent"
      , el "auth" "token" "5. Issue"
      , el "token" "client" "6. Access Token"
      , el "client" "resource" "7. API Call + Token"
      , el "resource" "client" "8. API Response"
      , el "client" "user" "9. Result"
      , ed "refresh" "auth" "10. Refresh"
      ]
  , dagreRankDir: LeftRight
  , dotSource: joinWith "\n"
      [ "digraph oauth {"
      , "  rankdir=LR; bgcolor=\"transparent\";"
      , "  node [shape=box, style=\"rounded,filled\", fontname=\"sans-serif\", fontsize=11];"
      , "  edge [color=\"#666\", penwidth=1.5, arrowsize=0.8];"
      , "  user [label=\"Resource\\nOwner (User)\", fillcolor=\"#bbdefb\"];"
      , "  client [label=\"Client\\n(App)\", fillcolor=\"#ffe0b2\"];"
      , "  auth [label=\"Authorization\\nServer\", fillcolor=\"#c8e6c9\"];"
      , "  resource [label=\"Resource\\nServer (API)\", fillcolor=\"#f8bbd0\"];"
      , "  token [label=\"Access\\nToken\", shape=diamond, fillcolor=\"#e1bee7\"];"
      , "  refresh [label=\"Refresh\\nToken\", shape=diamond, fillcolor=\"#e1bee7\"];"
      , "  user -> client [label=\"1. Request\"];"
      , "  client -> auth [label=\"2. Auth Request\"];"
      , "  auth -> user [label=\"3. User Grants\"];"
      , "  user -> auth [label=\"4. Consent\"];"
      , "  auth -> token [label=\"5. Issue\"];"
      , "  token -> client [label=\"6. Access Token\"];"
      , "  client -> resource [label=\"7. API Call + Token\"];"
      , "  resource -> client [label=\"8. API Response\"];"
      , "  client -> user [label=\"9. Result\"];"
      , "  refresh -> auth [label=\"10. Refresh\", style=dashed];"
      , "}"
      ]
  , nodeInfo:
      [ mkInfo "user" "Resource Owner (User)"
          "The end user who owns the data and grants permission to the application to access it."
      , mkInfo "client" "Client (App)"
          "The third-party application requesting access to the user's data on the resource server."
      , mkInfo "auth" "Authorization Server"
          "Issues access tokens after authenticating the user and obtaining their consent."
      , mkInfo "resource" "Resource Server (API)"
          "The API that hosts the protected user data. Validates access tokens before serving requests."
      , mkInfo "token" "Access Token"
          "A short-lived credential that the client uses to access the resource server. Typically a JWT."
      , mkInfo "refresh" "Refresh Token"
          "A long-lived credential used to obtain new access tokens without requiring user re-authentication."
      ]
  , dagreStyles:
      [ sEntry "user" "Owner (User)"
      , sProcess "client" "App"
      , sCache "auth" "Server"
      , sDist "resource" "Server (API)"
      , sAdvanced "token" "Token"
      , sAdvanced "refresh" "Token"
      ]
  , dagreClusters: []
  }

shardingDiagram :: DiagramSpec
shardingDiagram =
  { id: "sharding"
  , title: "Database Sharding"
  , category: "Auth & Data"
  , description:
      "Horizontal partitioning: a shard router distributes data across multiple database servers using a hash function."
  , dagreNodes:
      [ mkNode "app" "Application"
      , mkNode "router" "Shard Router"
      , mkNode "shard1" "Shard 1"
      , mkNode "shard2" "Shard 2"
      , mkNode "shard3" "Shard 3"
      ]
  , dagreEdges:
      [ el "app" "router" "query"
      , el "router" "shard1" "hash % 3 == 0"
      , el "router" "shard2" "hash % 3 == 1"
      , el "router" "shard3" "hash % 3 == 2"
      ]
  , dagreRankDir: TopBottom
  , dotSource: joinWith "\n"
      [ "digraph sharding {"
      , "  rankdir=TB; bgcolor=\"transparent\";"
      , "  node [shape=box, style=\"rounded,filled\", fontname=\"sans-serif\", fontsize=11];"
      , "  edge [color=\"#666\", penwidth=1.5, arrowsize=0.8];"
      , "  app [label=\"Application\", fillcolor=\"#bbdefb\"];"
      , "  router [label=\"Shard Router\\n(hash(key) % N)\", shape=diamond, fillcolor=\"#ffe0b2\"];"
      , "  shard1 [label=\"Shard 1\\n(user_id: 1-1000)\", fillcolor=\"#c8e6c9\"];"
      , "  shard2 [label=\"Shard 2\\n(user_id: 1001-2000)\", fillcolor=\"#c8e6c9\"];"
      , "  shard3 [label=\"Shard 3\\n(user_id: 2001-3000)\", fillcolor=\"#c8e6c9\"];"
      , "  app -> router [label=\"query\"];"
      , "  router -> shard1 [label=\"hash % 3 == 0\"];"
      , "  router -> shard2 [label=\"hash % 3 == 1\"];"
      , "  router -> shard3 [label=\"hash % 3 == 2\"];"
      , "}"
      ]
  , nodeInfo:
      [ mkInfo "app" "Application"
          "The application sends queries to the shard router, which determines which shard to route each query to."
      , mkInfo "router" "Shard Router (hash(key) % N)"
          "Computes a hash of the partition key (e.g., user_id) and takes modulo N to determine the target shard."
      , mkInfo "shard1" "Shard 1 (user_id: 1-1000)"
          "First database partition. Contains a subset of users. Independent CPU, memory, and disk."
      , mkInfo "shard2" "Shard 2 (user_id: 1001-2000)"
          "Second database partition. Each shard is self-contained and does not share resources with others."
      , mkInfo "shard3" "Shard 3 (user_id: 2001-3000)"
          "Third database partition. Adding more shards allows linear write scaling."
      ]
  , dagreStyles:
      [ sEntry "app" ""
      , sProcess "router" "hash(key) % N"
      , sCache "shard1" "user_id: 1-1000"
      , sCache "shard2" "user_id: 1001-2000"
      , sCache "shard3" "user_id: 2001-3000"
      ]
  , dagreClusters: []
  }

allDiagrams :: Array DiagramSpec
allDiagrams =
  [ scaleDiagram
  , blueprintDiagram
  , cacheDiagram
  , cicdDiagram
  , youtubeDiagram
  , kafkaDiagram
  , oauthDiagram
  , shardingDiagram
  ]

categories :: Array Category
categories =
  [ { name: "Architecture", ids: [ "scale", "blueprint", "cache" ] }
  , { name: "Pipeline", ids: [ "cicd", "youtube", "kafka" ] }
  , { name: "Auth & Data", ids: [ "oauth", "sharding" ] }
  ]

findDiagram :: String -> Maybe DiagramSpec
findDiagram id = head (filter (\d -> d.id == id) allDiagrams)

findNodeInfo :: DiagramSpec -> String -> Maybe NodeInfo
findNodeInfo diag nodeId = head (filter (\n -> n.id == nodeId) diag.nodeInfo)
