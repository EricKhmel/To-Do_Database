USE master
GO


/******   Object: Database ToDo   ******/
IF DB_ID('ToDo') IS NOT NULL 
	DROP DATABASE ToDo
GO	

CREATE DATABASE ToDo
GO

USE ToDo
GO


/******   Object: Table Users   ******/
CREATE TABLE Users(
	userID		INT				IDENTITY(1,1) NOT NULL
	,username	VARCHAR(50)					  NOT NULL	UNIQUE
	,password	NVARCHAR(150)			  NULL		DEFAULT(NULL)
	,salt		UNIQUEIDENTIFIER			  NOT NULL	DEFAULT(NEWID())
	,loginToken	UNIQUEIDENTIFIER			  NULL		DEFAULT(NULL)
	,isDeleted	BIT							  NOT NULL	DEFAULT 0
	,CONSTRAINT PK_Users PRIMARY KEY CLUSTERED(userID ASC)
)
GO

/******   Object: Table Lists   ******/
CREATE TABLE Lists(
	listID		INT				IDENTITY(1,1)							NOT NULL
	,userID		INT				FOREIGN KEY REFERENCES Users(userID)	NOT NULL
	,listName	VARCHAR(50)												NOT NULL
	,CONSTRAINT PK_Lists PRIMARY KEY CLUSTERED(listID ASC)
)
GO

/******   Object: Table Tasks   ******/
CREATE TABLE Tasks(
	taskID				INT			IDENTITY(1,1)							NOT NULL
	,userID				INT			FOREIGN KEY REFERENCES Users(userID)	NOT NULL
	,listID				INT			FOREIGN KEY REFERENCES Lists(listID)	NOT NULL
	,taskDescription	VARCHAR(50)											NOT NULL
	 CONSTRAINT PK_Tasks PRIMARY KEY CLUSTERED(taskID ASC)
)
GO


/****** Stored Procedures ******/
CREATE PROCEDURE Add_ToDo_Users
	@username	VARCHAR(50)	
	,@password	VARCHAR(50)		
AS BEGIN SET NOCOUNT ON 
	INSERT Users (username, password) VALUES (@username, @password)
	UPDATE Users SET password = HASHBYTES('SHA2_512', CAST(password AS NVARCHAR(150)))
END
GO

CREATE PROCEDURE Update_ToDo_Users
	@userID		INT
	,@username	VARCHAR(50)	
	,@password	VARCHAR(50)	
AS BEGIN SET NOCOUNT ON 
	UPDATE 
		Users 
	SET 
		username = @username
		,password = HASHBYTES('SHA2_512', CAST(@password AS NVARCHAR(150)))
	WHERE 
		userID = @userID
END
GO

CREATE PROCEDURE softDelete_ToDo_Users 
	@userID		INT
AS BEGIN SET NOCOUNT ON 
	UPDATE 
		Users 
	SET 
		isDeleted = 1 
	WHERE 
		userID = @userID
END
GO


CREATE PROCEDURE ToDo_Login
	@username	VARCHAR(50)	
	,@password	VARCHAR(50)	
AS BEGIN SET NOCOUNT ON 
	DECLARE @ret UNIQUEIDENTIFIER 
	IF EXISTS( 
		SELECT 
			NULL 
		FROM	
			Users 
		WHERE 
			username = @username AND
			password = HASHBYTES('SHA2_512', CAST(@password AS NVARCHAR(150)))
	)	BEGIN
			SELECT @ret = loginToken FROM Users WHERE username = @username;
			IF(@ret IS NULL) BEGIN
				SELECT @ret = NEWID();
				UPDATE Users SET loginToken = @ret WHERE username = @username
			END
	END 

	SELECT @ret AS loginToken
END
GO

CREATE PROCEDURE ToDo_Logout
	@loginToken UNIQUEIDENTIFIER
AS BEGIN SET NOCOUNT ON 
	UPDATE 
		Users 
	SET 
		loginToken = NULL 
	WHERE 
		loginToken = @LoginToken
END
GO


CREATE PROCEDURE Add_ToDo_Lists 
	@userID	INT			
	,@listName	VARCHAR(50)
AS BEGIN SET NOCOUNT ON 
	INSERT Lists (userID, listName) VALUES (@userID, @listName)
END
GO

CREATE PROCEDURE View_ToDo_ListsByUser 
	@userID	INT
AS BEGIN SET NOCOUNT ON 
	SELECT	
		listID, listName
	FROM	
		Lists
	WHERE	
		userID = @userID
END
GO


CREATE PROCEDURE Add_ToDo_Tasks 
	@userID				INT			
	,@listID			INT			
	,@taskDescription	VARCHAR(50)
AS BEGIN SET NOCOUNT ON 
	INSERT Tasks (userID, listID, taskDescription) VALUES (@userID, @listID, @taskDescription)
END
GO

CREATE PROCEDURE Update_ToDo_Tasks
	@taskID				INT
	,@taskDescription	VARCHAR(50)
AS BEGIN SET NOCOUNT ON 
	UPDATE 
		Tasks 
	SET 
		taskDescription = @taskDescription
	WHERE 
		taskID = @taskID
END
GO

CREATE PROCEDURE Delete_ToDo_Tasks 
	@taskID		INT
AS BEGIN SET NOCOUNT ON 
	DELETE
		Tasks 
	WHERE 
		taskID = @taskID
END
GO

CREATE PROCEDURE View_ToDo_TasksInList 
	@userID	 	INT
	,@listID	INT
AS BEGIN SET NOCOUNT ON 
	SELECT 
		taskID, taskDescription
	FROM 
		Tasks 
	WHERE 
		userID = @userID AND listID = @listID
END



/****** Testing ******/
--Add_ToDo_Users 'allie', 'abc123'
--Add_ToDo_Users 'betty', 'def456'
--Add_ToDo_Users 'charlie', 'ghi789'

--Update_ToDo_Users 2, 'brad', 'DEF456' 

--softDelete_ToDo_Users 3

--ToDo_Login 'brad', 'DEF456'
--ToDo_Logout 'E8CA3765-C1E4-4910-A07E-D0E23D5D8F40'
--ToDo_Login 'charlie', 'ghi789'

--Add_ToDo_Lists 1, 'Home'
--Add_ToDo_Lists 1, 'Work'
--Add_ToDo_Lists 2, 'Home'
--Add_ToDo_Lists 2, 'Shopping'

--View_ToDo_ListsByUser 1
--View_ToDo_ListsByUser 2

--Add_ToDo_Tasks 1, 1, 'Clean'
--Add_ToDo_Tasks 1, 1, 'Laundry'
--Add_ToDo_Tasks 1, 2, 'Write report'
--Add_ToDo_Tasks 2, 3, 'Cook'
--Add_ToDo_Tasks 2, 4, 'Buy milk'
--Add_ToDo_Tasks 2, 4, 'Buy meat'

--Update_ToDo_Tasks 1, 'Clean kitchen'
--Update_ToDo_Tasks 5, 'Buy candy'

--Delete_ToDo_Tasks 4
--Delete_ToDo_Tasks 5
--Delete_ToDo_Tasks 6

--View_ToDo_TasksInList 1, 1
--View_ToDo_TasksInList 1, 2
--View_ToDo_TasksInList 2, 3
--View_ToDo_TasksInList 2, 4
