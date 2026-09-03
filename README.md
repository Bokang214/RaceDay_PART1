# RaceDay_PART1
RaceDay RaceDay is a full-stack, web-based event management system for the South African road running, walking, and cycling community. 
● Event Organisers can create and manage events and categories, capture participant results, and view all enrolments for their events. 
● Participants (stored as User records with Role = 'Participant') can create an account, browse upcoming events, enter an event by selecting a category, view their own enrolments, and track their personal result history. 

This assignment has 3 parts: Part Scope Part 1 (this submission) Plan the system: Entity Relationship Diagram, full API endpoint plan, and a SQL Server database script. No application code is written in this part. 
Part 2 Build the RESTful API in C# against the Part 1 plan, connect it to the database, and add unit tests with GitHub Actions CI/CD. 
Part 3 Build the MVC web application that consumes the API, integrate Azure Blob Storage, and containerise the application with Docker. 
Roles Role Capabilities Organiser Create, edit, and delete events; manage event categories; capture participant results; view all enrolments for their events. Participant Register an account; browse events; enter an event by selecting a category; view their own enrolments; track their personal results.

Role-based access is planned at the API level in this part (see docs/API_Endpoint_Plan.md, "Role Required" column) and will be enforced in Part 2's implementation and reflected in Part 3's MVC interface.

Part 1 Deliverables 
Section A - Entity Relationship Diagram (docs/ERD_UML.png) Six entities: Organisers, User, Event, Category, Enrolment, Result. Organisers is a standalone table for event organisers; User holds participant accounts (a Role column exists for future extensibility but every row is currently 'Participant'). Relationships are shown in UML notation - a directional arrow from the "one" side to the related entity, labelled with multiplicity (1;* for one-to-many, 1;1 for one-to-one). Primary keys and foreign keys are labelled on each entity. Enrolment deliberately carries both EventId and CategoryId (not just CategoryId) - a denormalisation kept from the team's reviewed ERD; see the design note at the top of database_schema.sql for how the resulting cascade-delete conflict was resolved. The SQL script in Section C matches this ERD exactly - same entities, same attributes, same relationships, no unexplained deviations. (docs/ERD.png is an older crow's-foot version of an earlier draft of the model, kept for reference only - it does not reflect the current, team-reviewed structure; only ERD_UML.png should be treated as current.) 

Section B - API Endpoint Plan (docs/API_Endpoint_Plan.md) Covers all six required functional areas (Authentication, User Profile, Events, Categories, Event Enrolments, Results) with HTTP Method, Route, Description, Role Required, Request Body, and Expected Response (including failure status codes) for every endpoint. This plan will be implemented as-is in Part 2; any deviation will be explained there.

Section C - SQL Database Script (docs/database_schema.sql) 
● CREATE TABLE statements for all six entities in the ERD. 
● All primary keys, foreign keys, NOT NULL, DEFAULT, and CHECK constraints defined. 
● Seed data: 2 Organisers, 2 Users, 3 Events, categories for every event (7 total), 5 sample enrolments, and 2 sample results. 
● The script is idempotent (drops and recreates the RaceDay database) so it can be re-run cleanly on the same instance, and ends with a verification query that prints row counts for every table. Setup Notes (Section C script)
