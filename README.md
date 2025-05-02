# Service Oriented Architecture for Text Collections

This is our Service Oriented Architecture for making available (enriched) Text Collections:

```{.mermaid format=svg}
flowchart TD


    user@{ shape: sl-rect, label: "End-user (Researcher)<br>in web browser"}
    user -- "HTTPS (UI)" --> textannoviz
    subgraph frontend
        textannoviz[/"<b>TextAnnoViz</b><br>(web front-end)"/]
    end

    techuser@{ shape: sl-rect, label: "Technical user/machine<br>via a web client"}

    techuser -- "HTTPS + Broccoli API" --> broccoli
    subgraph middleware
        textannoviz -- HTTP --> broccoli
        broccoli[/"<b>Broccoli</b><br><i>(broker)</i>"/]

        broccoli_annorepoclient@{shape: subproc, label: "annorepo-client"}
        broccoli --> broccoli_annorepoclient 
    end


    subgraph backend
    
        annorepo[/"<b>Annorepo</b><br><i>(web annotation server)</i>"/]
        mongodb[/"MongoDB<br><i>(NoSQL database server)</i>"/]
        annorepo_db[("Annotation Database")]
        annorepo --> mongodb --> annorepo_db

        elasticsearch[/"ElasticSearch<br><i>(Search engine)</i>"/]
        textindex[("Text index")]
        texts@{ shape: docs, label: "Text files<br><i>(plain text, UTF-8)</i>"}
        textscans@{ shape: docs, label: "Text Scans<br><i>(image files)</i>"}

        textsurf[/"<b>Textsurf</b><br>(text server)"/]
        textframe@{shape: subproc, label: "Textframe<br><i>(text referencing library)</i>"}


        cantaloupe[/"<b>Cantaloupe</b><br><i>(IIIF Image server)</i>"/]
        manifests@{ shape: docs, label: "IIIF Manifests"}
        cantaloupe --> textscans
        cantaloupe --> manifests


        sdswitch[/"SD-Switch<br><i>(broker for various<br>structured data services)</i>"/]

        broccoli_annorepoclient -- "HTTP + W3C Web Annotation Protocol" --> annorepo
        broccoli -- "HTTP + IIIF Image API" --> cantaloupe
        broccoli -- "HTTP" --> sdswitch
        broccoli -- "HTTP + Textsurf API" --> textsurf

        broccoli --> elasticsearch --> textindex

        textsurf --> textframe -->  texts
        textsurf --> texts

        textannoviz -- "HTTP + IIIF Presentation API" --> cantaloupe
    end


    classDef thirdparty fill:#ccc,color:#111
    class cantaloupe,mongodb,elasticsearch thirdparty
```

## Legend:

* Arrows follow caller direction, response data flows in opposite direction. Edge labels denote communication protocols.
* Rectangles represent processes.
* Parallelograms represent networked services.
* Rectangles with an extra marked block left and right represent software libraries
* Third party software is grayed out

