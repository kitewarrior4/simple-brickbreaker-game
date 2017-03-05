#include <iostream>
#include <cmath>
#include <fstream>
#include <vector>
#include<time.h>

#include <glad/glad.h>
#include <GLFW/glfw3.h>

#define GLM_FORCE_RADIANS
#include <glm/glm.hpp>
#include <glm/gtx/transform.hpp>
#include <glm/gtc/matrix_transform.hpp>

using namespace std;

struct VAO {
    GLuint VertexArrayID;
    GLuint VertexBuffer;
    GLuint ColorBuffer;

    GLenum PrimitiveMode;
    GLenum FillMode;
    int NumVertices;
};
typedef struct VAO VAO;

struct GLMatrices {
	glm::mat4 projection;
	glm::mat4 model;
	glm::mat4 view;
	GLuint MatrixID;
} Matrices;

GLuint programID;

/* Function to load Shaders - Use it as it is */
GLuint LoadShaders(const char * vertex_file_path,const char * fragment_file_path) {

	// Create the shaders
	GLuint VertexShaderID = glCreateShader(GL_VERTEX_SHADER);
	GLuint FragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);

	// Read the Vertex Shader code from the file
	std::string VertexShaderCode;
	std::ifstream VertexShaderStream(vertex_file_path, std::ios::in);
	if(VertexShaderStream.is_open())
	{
		std::string Line = "";
		while(getline(VertexShaderStream, Line))
			VertexShaderCode += "\n" + Line;
		VertexShaderStream.close();
	}

	// Read the Fragment Shader code from the file
	std::string FragmentShaderCode;
	std::ifstream FragmentShaderStream(fragment_file_path, std::ios::in);
	if(FragmentShaderStream.is_open()){
		std::string Line = "";
		while(getline(FragmentShaderStream, Line))
			FragmentShaderCode += "\n" + Line;
		FragmentShaderStream.close();
	}

	GLint Result = GL_FALSE;
	int InfoLogLength;

	// Compile Vertex Shader
	printf("Compiling shader : %s\n", vertex_file_path);
	char const * VertexSourcePointer = VertexShaderCode.c_str();
	glShaderSource(VertexShaderID, 1, &VertexSourcePointer , NULL);
	glCompileShader(VertexShaderID);

	// Check Vertex Shader
	glGetShaderiv(VertexShaderID, GL_COMPILE_STATUS, &Result);
	glGetShaderiv(VertexShaderID, GL_INFO_LOG_LENGTH, &InfoLogLength);
	std::vector<char> VertexShaderErrorMessage(InfoLogLength);
	glGetShaderInfoLog(VertexShaderID, InfoLogLength, NULL, &VertexShaderErrorMessage[0]);
	fprintf(stdout, "%s\n", &VertexShaderErrorMessage[0]);

	// Compile Fragment Shader
	printf("Compiling shader : %s\n", fragment_file_path);
	char const * FragmentSourcePointer = FragmentShaderCode.c_str();
	glShaderSource(FragmentShaderID, 1, &FragmentSourcePointer , NULL);
	glCompileShader(FragmentShaderID);

	// Check Fragment Shader
	glGetShaderiv(FragmentShaderID, GL_COMPILE_STATUS, &Result);
	glGetShaderiv(FragmentShaderID, GL_INFO_LOG_LENGTH, &InfoLogLength);
	std::vector<char> FragmentShaderErrorMessage(InfoLogLength);
	glGetShaderInfoLog(FragmentShaderID, InfoLogLength, NULL, &FragmentShaderErrorMessage[0]);
	fprintf(stdout, "%s\n", &FragmentShaderErrorMessage[0]);

	// Link the program
	fprintf(stdout, "Linking program\n");
	GLuint ProgramID = glCreateProgram();
	glAttachShader(ProgramID, VertexShaderID);
	glAttachShader(ProgramID, FragmentShaderID);
	glLinkProgram(ProgramID);

	// Check the program
	glGetProgramiv(ProgramID, GL_LINK_STATUS, &Result);
	glGetProgramiv(ProgramID, GL_INFO_LOG_LENGTH, &InfoLogLength);
	std::vector<char> ProgramErrorMessage( max(InfoLogLength, int(1)) );
	glGetProgramInfoLog(ProgramID, InfoLogLength, NULL, &ProgramErrorMessage[0]);
	fprintf(stdout, "%s\n", &ProgramErrorMessage[0]);

	glDeleteShader(VertexShaderID);
	glDeleteShader(FragmentShaderID);

	return ProgramID;
}

static void error_callback(int error, const char* description)
{
    fprintf(stderr, "Error: %s\n", description);
}

void quit(GLFWwindow *window)
{
    glfwDestroyWindow(window);
    glfwTerminate();
   exit(EXIT_SUCCESS);
}


/* Generate VAO, VBOs and return VAO handle */
struct VAO* create3DObject (GLenum primitive_mode, int numVertices, const GLfloat* vertex_buffer_data, const GLfloat* color_buffer_data, GLenum fill_mode=GL_FILL)
{
    struct VAO* vao = new struct VAO;
    vao->PrimitiveMode = primitive_mode;
    vao->NumVertices = numVertices;
    vao->FillMode = fill_mode;

    // Create Vertex Array Object
    // Should be done after CreateWindow and before any other GL calls
    glGenVertexArrays(1, &(vao->VertexArrayID)); // VAO
    glGenBuffers (1, &(vao->VertexBuffer)); // VBO - vertices
    glGenBuffers (1, &(vao->ColorBuffer));  // VBO - colors

    glBindVertexArray (vao->VertexArrayID); // Bind the VAO
    glBindBuffer (GL_ARRAY_BUFFER, vao->VertexBuffer); // Bind the VBO vertices
    glBufferData (GL_ARRAY_BUFFER, 3*numVertices*sizeof(GLfloat), vertex_buffer_data, GL_STATIC_DRAW); // Copy the vertices into VBO
    glVertexAttribPointer(
                          0,                  // attribute 0. Vertices
                          3,                  // size (x,y,z)
                          GL_FLOAT,           // type
                          GL_FALSE,           // normalized?
                          0,                  // stride
                          (void*)0            // array buffer offset
                          );

    glBindBuffer (GL_ARRAY_BUFFER, vao->ColorBuffer); // Bind the VBO colors
    glBufferData (GL_ARRAY_BUFFER, 3*numVertices*sizeof(GLfloat), color_buffer_data, GL_STATIC_DRAW);  // Copy the vertex colors
    glVertexAttribPointer(
                          1,                  // attribute 1. Color
                          3,                  // size (r,g,b)
                          GL_FLOAT,           // type
                          GL_FALSE,           // normalized?
                          0,                  // stride
                          (void*)0            // array buffer offset
                          );

    return vao;
}

/* Generate VAO, VBOs and return VAO handle - Common Color for all vertices */
struct VAO* create3DObject (GLenum primitive_mode, int numVertices, const GLfloat* vertex_buffer_data, const GLfloat red, const GLfloat green, const GLfloat blue, GLenum fill_mode=GL_FILL)
{
    GLfloat* color_buffer_data = new GLfloat [3*numVertices];
    for (int i=0; i<numVertices; i++) {
        color_buffer_data [3*i] = red;
        color_buffer_data [3*i + 1] = green;
        color_buffer_data [3*i + 2] = blue;
    }

    return create3DObject(primitive_mode, numVertices, vertex_buffer_data, color_buffer_data, fill_mode);
}

/* Render the VBOs handled by VAO */
void draw3DObject (struct VAO* vao)
{
    // Change the Fill Mode for this object
    glPolygonMode (GL_FRONT_AND_BACK, vao->FillMode);

    // Bind the VAO to use
    glBindVertexArray (vao->VertexArrayID);

    // Enable Vertex Attribute 0 - 3d Vertices
    glEnableVertexAttribArray(0);
    // Bind the VBO to use
    glBindBuffer(GL_ARRAY_BUFFER, vao->VertexBuffer);

    // Enable Vertex Attribute 1 - Color
    glEnableVertexAttribArray(1);
    // Bind the VBO to use
    glBindBuffer(GL_ARRAY_BUFFER, vao->ColorBuffer);

    // Draw the geometry !
    glDrawArrays(vao->PrimitiveMode, 0, vao->NumVertices); // Starting from vertex 0; 3 vertices total -> 1 triangle
}

/**************************
 * Customizable functions *
 **************************/


float triangle_rot_dir = 1;
float rectangle_rot_dir = 1;
bool triangle_rot_status = true;
bool rectangle_rot_status = true;
int width = 1024;
int height = 768;

float camera_rotation_angle = 90;
float rectangle_rotation = 0;
float triangle_rotation = 0;
glm::vec3 cannonPos = glm::vec3(-3.86f,0,0);
float cannonLimit = 2.00;
float bucketLimit = 3.00;
double mouseX;
double mouseY;
double mouseY2;
float cannonRotation;
float laserSpeed =2;
bool laserControl=false;
bool ctrlMod=false;
bool altMod=false;
bool cannonLock = false;
bool gameOver = false;
float blockSpeed = 0.01;
bool leftMouseDown=false;
bool rightMouseDown=false;
float zoom = 0;
float pan = 0;
int score = 0;
int blockNumber = 100;
int globalKey;
int globalAction;
int lives = 20;
int misfires = 0;
int wrongtarget = 0;
int wrongcollect = 0;
int shotsfired = 0;

glm::vec3 bucketScale = glm::vec3(0.5,0.5,1);
glm::vec3 mirrorScale = glm::vec3(0.15,0.01,1);
glm::vec3 blockScale = glm::vec3(0.05, 0.1, 1);
glm::vec3 laserScale = glm::vec3(0.025,0.05,1);


struct coord
{
  double X;
  double Y;
};

struct block
{
  int number;
  int color;
  glm::vec3 T;
  bool collide;
  bool falling;
  bool out;
};

struct laser
{
  glm::vec3 T;
  glm::vec3 T2;
  glm::vec3 S;
  float speed;
  float R;
  float R2;
  bool out;
  int lastCollided;
  bool collideBlock;
  glm::mat4 matrix;
};

struct bucket
{
  glm::vec3 T;
};

struct mirror
{
  glm::vec3 T;
  float R;
};

std::vector<block> vBlock;
std::vector<laser> vLaser;
std::vector<mirror> vMirror;
bucket redBucket;
bucket greenBucket;
coord mouseCoord;
coord dragCoord;
coord bufferCoord;
glm::vec3 redDrag;
glm::vec3 greenDrag;
glm::vec3 cannonDrag;


coord getCoord()
{
  coord temp;
  temp.X = (8 + 2 * zoom) * (mouseX - width/2)/width + pan;
  temp.Y = -1* (8 + 2 * zoom) * (mouseY - height/2)/height;
  return temp;
}

void setBlock(int i)
{
  block temp;
  temp.number = i;
  temp.T = glm::vec3((float)(rand()%300)/100 -1.0, 50.0f, 0);
  temp.color = rand()%3;
  temp.falling = false;
  temp.collide = false;
  temp.out = false;
  vBlock.push_back(temp);
  // cout<<vBlock.size()<<endl;
}

void setLaser()
{
  laser temp;
  temp.T = cannonPos;
  temp.T2 = glm::vec3(0,20,0);
  temp.S = laserScale;
  temp.R = cannonRotation;
  temp.R2 = 0;
  temp.lastCollided = -1;
  temp.collideBlock = false;
  temp.out = false;
  temp.speed = laserSpeed;
  vLaser.push_back(temp);
  laserControl = false;
  shotsfired++;
};

/* Executed when a regular key is pressed/released/held-down */
/* Prefered for Keyboard events */
void keyboard (GLFWwindow* window, int key, int scancode, int action, int mods)
{
     // Function is called first on GLFW_PRESS.

    if (action == GLFW_RELEASE) {
        switch (key) {
            case GLFW_KEY_C:
                rectangle_rot_status = !rectangle_rot_status;
                break;
            case GLFW_KEY_P:
                triangle_rot_status = !triangle_rot_status;
                break;
            case GLFW_KEY_X:
                // do something ..
                break;

            case GLFW_KEY_W:
                cannonPos+=glm::vec3(0,0.05,0);
                break;
            case GLFW_KEY_S:
                cannonPos+=glm::vec3(0,-0.05,0);
                break;
            case GLFW_KEY_A:
                cannonLock = true;
                cannonRotation+=0.1;
                break;
            case GLFW_KEY_D:
                cannonLock = true;
                cannonRotation-=0.1;
                break;
            case GLFW_KEY_N:
                blockSpeed+=0.005;
                break;
            case GLFW_KEY_M:
                if(blockSpeed>0.005)
                blockSpeed-=0.005;
                break;
            case GLFW_KEY_LEFT_CONTROL:
                ctrlMod=false;
                break;
            case GLFW_KEY_RIGHT_CONTROL:
                ctrlMod=false;
                break;
            case GLFW_KEY_LEFT_ALT:
                altMod=false;
                break;
            case GLFW_KEY_RIGHT_ALT:
                altMod=false;
                break;
            default:
                break;
        }
    }
    else if (action == GLFW_PRESS) {
        switch (key) {
            case GLFW_KEY_ESCAPE:
                quit(window);
                break;
            case GLFW_KEY_LEFT_CONTROL:
                ctrlMod=true;
                break;
            case GLFW_KEY_RIGHT_CONTROL:
                ctrlMod=true;
                break;
            case GLFW_KEY_LEFT_ALT:
                altMod=true;
                break;
            case GLFW_KEY_RIGHT_ALT:
                altMod=true;
                break;
            case GLFW_KEY_LEFT:
                if(ctrlMod) redBucket.T.x-=0.1;
                if(altMod) greenBucket.T.x-=0.1;
                if(!ctrlMod && !altMod)pan-=0.1;
                break;

            case GLFW_KEY_RIGHT:
                if(ctrlMod) redBucket.T.x+=0.1;
                if(altMod) greenBucket.T.x+=0.1;
                if(!ctrlMod && !altMod)pan+=0.1;
                break;

            case GLFW_KEY_UP:
                zoom+=0.1;
                break;
            case GLFW_KEY_DOWN:
                zoom-=0.1;
                break;
            case GLFW_KEY_SPACE:
                if(laserControl)
                setLaser();
                break;

            default:
                break;
        }

      }


    else if (action == GLFW_REPEAT){
      switch (key) {
        case GLFW_KEY_W:
            cannonPos+=glm::vec3(0,0.05,0);
            break;
        case GLFW_KEY_S:
            cannonPos+=glm::vec3(0,-0.05,0);
            break;
        case GLFW_KEY_A:
            cannonRotation+=1;
            break;
        case GLFW_KEY_D:
            cannonRotation-=1;
            break;

        case GLFW_KEY_LEFT:
            if(ctrlMod) redBucket.T.x-=0.1;
            if(altMod) greenBucket.T.x-=0.1;
            break;
        case GLFW_KEY_RIGHT:
            if(ctrlMod) redBucket.T.x+=0.1;
            if(altMod) greenBucket.T.x+=0.1;
            break;
        default:
          break;
      }
    }
}

/* Executed for character input (like in text boxes) */
void keyboardChar (GLFWwindow* window, unsigned int key)
{
	switch (key) {
		case 'Q':
		case 'q':
            quit(window);
            break;
		default:
			break;
	}
}

/* Executed when a mouse button is pressed/released */
void mouseButton (GLFWwindow* window, int button, int action, int mods)
{
  globalKey = button;
  globalAction = action;
    switch (button) {
        case GLFW_MOUSE_BUTTON_LEFT:
            if(action == GLFW_PRESS)
            {
                leftMouseDown = true;
                dragCoord=getCoord();
                redDrag = redBucket.T;
                greenDrag = greenBucket.T;
                cannonDrag = cannonPos;
                // cout<<leftMouseDown<<endl;
            }
            if (action == GLFW_RELEASE)
              {
                leftMouseDown = false;
                // cout<<leftMouseDown<<endl;

                if(laserControl)
                setLaser();
            }
            break;

        // case GLFW_MOUSE_BUTTON_RIGHT:
        //     if (action == GLFW_RELEASE) {
        //         rectangle_rot_dir *= -1;
        //     }
        //     break;
        case GLFW_MOUSE_BUTTON_RIGHT:
        if(action == GLFW_PRESS)
        {
          rightMouseDown = true;
          dragCoord = getCoord();
        }
        if (action == GLFW_RELEASE)
        {
          rightMouseDown = false;
        }
        break;
        default:
            break;
    }

}


/* Executed when window is resized to 'width' and 'height' */
/* Modify the bounds of the screen here in glm::ortho or Field of View in glm::Perspective */
void reshapeWindow (GLFWwindow* window, int width, int height)
{
    int fbwidth=width, fbheight=height;
    /* With Retina display on Mac OS X, GLFW's FramebufferSize
     is different from WindowSize */
    glfwGetFramebufferSize(window, &fbwidth, &fbheight);

	GLfloat fov = 90.0f;

	// sets the viewport of openGL renderer
	glViewport (0, 0, (GLsizei) fbwidth, (GLsizei) fbheight);

	// set the projection matrix as perspective
	/* glMatrixMode (GL_PROJECTION);
	   glLoadIdentity ();
	   gluPerspective (fov, (GLfloat) fbwidth / (GLfloat) fbheight, 0.1, 500.0); */
	// Store the projection matrix in a variable for future use
    // Perspective projection for 3D views
    // Matrices.projection = glm::perspective (fov, (GLfloat) fbwidth / (GLfloat) fbheight, 0.1f, 500.0f);

    // Ortho projection for 2D views
    Matrices.projection = glm::ortho(-4.0f - zoom - pan, 4.0f + zoom + pan, -4.0f-zoom, 4.0f+zoom, 0.1f, 500.0f);
}

VAO *triangle, *rectangle, *trapezium;

// Creates the triangle object used in this sample code
void createTriangle (float R, float G, float B)
{
  /* ONLY vertices between the bounds specified in glm::ortho will be visible on screen */

  /* Define vertex array as used in glBegin (GL_TRIANGLES) */
  static const GLfloat vertex_buffer_data [] = {
    0, 1,0, // vertex 0
    -0.5,0,0, // vertex 1
    0.5,0,0, // vertex 2
  };

  static const GLfloat color_buffer_data [] = {
    R,G,B, // color 1
    R,G,B, // color 2
    R,G,B, // color 3
  };

  // create3DObject creates and returns a handle to a VAO that can be used later
  triangle = create3DObject(GL_TRIANGLES, 3, vertex_buffer_data, color_buffer_data, GL_FILL);
}

// Creates the rectangle object used in this sample code
void createRectangle (float R, float G, float B)
{
  // GL3 accepts only Triangles. Quads are not supported
  GLfloat vertex_buffer_data [] = {
    -1.2,-1,0, // vertex 1
    1.2,-1,0, // vertex 2
    1.2, 1,0, // vertex 3

    1.2, 1,0, // vertex 3
    -1.2, 1,0, // vertex 4
    -1.2,-1,0  // vertex 1
  };

 GLfloat color_buffer_data [] = {
    R,G,B,
    R,G,B,
    R,G,B,

    R,G,B,
    R,G,B,
    R,G,B
  };

  // create3DObject creates and returns a handle to a VAO that can be used later
  rectangle = create3DObject(GL_TRIANGLES, 6, vertex_buffer_data, color_buffer_data, GL_FILL);
}

void createTrapezium(float R, float G, float B)
{
  GLfloat vertex_buffer_data[] = {
    -0.5,0,0,
    -0.5,1,0,
    0.5,0,0,

    0.5,0,0,
    -0.5,1,0,
    0.5,1,0,

    0.5,1,0,
    1,0,0,
    0.5,0,0,

    -0.5,0,0,
    -0.5,1,0,
    -1,0,0

  };

  GLfloat color_buffer_data [] = {
    R,G,B,
    R,G,B,
    R,G,B,

    R,G,B,
    R,G,B,
    R,G,B,

    R,G,B,
    R,G,B,
    R,G,B,

    R,G,B,
    R,G,B,
    R,G,B
  };
  trapezium = create3DObject(GL_TRIANGLES, 12, vertex_buffer_data, color_buffer_data, GL_FILL);
}



/* Render the scene with openGL */
/* Edit this function according to your assignment */
glm::mat4 genModelMatrix(glm::vec3 translate, float rotate, glm::vec3 scale)
{
  glm::mat4 tempScale = glm::scale(glm::mat4(1.0f),scale);
  glm::mat4 tempTranslate = glm::translate(translate);
  glm::mat4 tempRotate = glm::rotate(rotate,glm::vec3(0,0,1));
  return tempTranslate*tempRotate*tempScale;
}

bool checkCollision(glm::vec3 a, glm::vec3 b, int type)
{
  if(type==0)
   return (abs(a.x - b.x) < 0.1 && abs(a.y - b.y) < 0.1);
  if(type==1)
  return (abs(a.x - b.x) < 0.4 && abs (a.y - b.y) < 0.1);
  if(type==2)
  {
    // cout<<a.x<<' '<<a.y<<' '<<b.x<<' '<<b.y<<endl;
    return (abs(a.x - b.x) < 0.1 && abs (a.y - b.y) < 0.4);
  }
}

void scroll_callback(GLFWwindow* window, double xoffset, double yoffset)
{
  if(yoffset == 1)
    zoom+=0.1;
  else
    zoom-=0.1;
}

void draw ()
{
  // clear the color and depth in the frame buffer
  glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  // use the loaded shader program
  // Don't change unless you know what you are doing
  glUseProgram (programID);

  // Eye - Location of camera. Don't change unless you are sure!!
  glm::vec3 eye ( 5*cos(camera_rotation_angle*M_PI/180.0f), 0, 5*sin(camera_rotation_angle*M_PI/180.0f) );
  // Target - Where is the camera looking at.  Don't change unless you are sure!!
  glm::vec3 target (0, 0, 0);
  // Up - Up vector defines tilt of camera.  Don't change unless you are sure!!
  glm::vec3 up (0, 1, 0);

  // Compute Camera matrix (view)
  // Matrices.view = glm::lookAt( eye, target, up ); // Rotating Camera for 3D
  //  Don't change unless you are sure!!
  Matrices.view = glm::lookAt(glm::vec3(0,0,3), glm::vec3(0,0,0), glm::vec3(0,1,0)); // Fixed camera for 2D (ortho) in XY plane

  // Compute ViewProject matrix as view/camera might not be changed for this frame (basic scenario)
  //  Don't change unless you are sure!!
  glm::mat4 VP = Matrices.projection * Matrices.view;

  // Send our transformation to the currently bound shader, in the "MVP" uniform
  // For each model you render, since the MVP will be different (at least the M part)
  //  Don't change unless you are sure!!
  glm::mat4 MVP;	// MVP = Projection * View * Model

  // Load identity to model matrix
  Matrices.model = glm::mat4(1.0f);

  /* Render your scene */

  if(rightMouseDown)
  {
    pan+=-0.1* (mouseCoord.X - dragCoord.X);
    // cout<<pan<<endl;
  }


  Matrices.projection = glm::ortho(-4.0f - zoom + pan, 4.0f + zoom + pan, -4.0f-zoom, 4.0f+zoom, 0.1f, 500.0f);

  for (int i = 0; i < vBlock.size(); i++)
  {
    for(int j =0 ; j < vLaser.size(); ++j)
    {
      glm::vec3 lT = glm::vec3(vLaser[j].matrix[3]);
      glm::vec3 bT = vBlock[i].T;

      if(checkCollision(lT,bT,0))
      {
         vBlock[i].collide = true;
         if(vBlock[i].color == 0) score+=blockSpeed*1000;
         else
         {
           score-=10;
           lives--;
           wrongtarget++;
         }
         vLaser[j].collideBlock = true;
        //  cout<<"score: "<<score<<endl;
         cout<<"lives: "<<lives<<endl<<endl;
      }

    }



    if(checkCollision(vBlock[i].T,greenBucket.T,1))
    {
      vBlock[i].collide = true;
      if(vBlock[i].color == 2)
        score+=1000*blockSpeed;
      else if(vBlock[i].color == 0) gameOver = true;
      else
      {
        score-=10;
        lives--;
        wrongcollect++;
      }
        // cout<<"score: "<<score<<endl;
        cout<<"lives: "<<lives<<endl<<endl;

    }
    if(checkCollision(vBlock[i].T,redBucket.T,1))
    {
      vBlock[i].collide = true;
      if(vBlock[i].color == 1)
        score+=100*blockSpeed;
      else if(vBlock[i].color == 0) gameOver = true;
      else
      {
        score-=10;
        lives--;
        wrongcollect++;
      }

        // cout<<"score: "<<score<<endl;
        cout<<"lives: "<<lives<<endl<<endl;

    }
    if(vBlock[i].falling) vBlock[i].T.y-=blockSpeed;
    Matrices.model = genModelMatrix(vBlock[i].T, 0, blockScale);
    MVP = VP * Matrices.model;

    if(vBlock[i].color ==0) createRectangle(0,0,0);
    else if(vBlock[i].color ==1) createRectangle(1,0,0);
    else createRectangle(0,1,0);

    if(vBlock[i].T.y < -4)
    {
      vBlock[i].out= true;
      lives--;
      cout<<"lives: "<<lives<<endl;
    }

    if(vBlock[i].out ||  vBlock[i].collide)
    {
      vBlock.erase(vBlock.begin() + i);
      setBlock(i);
      // cout<<"Block: "<<vBlock.size()<<endl;
    }

    glUniformMatrix4fv(Matrices.MatrixID, 1, GL_FALSE, &MVP[0][0]);
    draw3DObject(rectangle);
  }

  if( leftMouseDown && abs(dragCoord.X - cannonDrag.x) <= 0.25 && abs(dragCoord.Y - cannonDrag.y) <=0.5)
  {
    // select = 0;
    cannonPos.y = mouseCoord.Y;
    Matrices.model = genModelMatrix(cannonPos, M_PI, glm::vec3(1,1,1));
    MVP = VP * Matrices.model;
    glUniformMatrix4fv(Matrices.MatrixID, 1, GL_FALSE, &MVP[0][0]);
    createRectangle(1,1,0);
    draw3DObject(rectangle);
    laserControl = false;
  }

  else if(leftMouseDown && abs(redDrag.x - dragCoord.X) <= 0.2 && abs(redDrag.y - dragCoord.Y) <= 0.5)
  {
    // select = 1;
    redBucket.T.x = mouseCoord.X;
    Matrices.model = genModelMatrix(redBucket.T + glm::vec3(0,-0.25,0), M_PI, glm::vec3(0.5,0.5,1));
    MVP = VP * Matrices.model;
    glUniformMatrix4fv(Matrices.MatrixID, 1, GL_FALSE, &MVP[0][0]);
    createRectangle(1,1,0);
    draw3DObject(rectangle);
    laserControl = false;

  }

  else if(leftMouseDown && abs(greenDrag.x - dragCoord.X) <= 0.2 && abs(greenDrag.y - dragCoord.Y) <= 0.5)
  {
    // select = 2;
    greenBucket.T.x = mouseCoord.X;
    Matrices.model = genModelMatrix(greenBucket.T + glm::vec3(0,-0.25,0), M_PI, glm::vec3(0.5,0.5,1));
    MVP = VP * Matrices.model;
    glUniformMatrix4fv(Matrices.MatrixID, 1, GL_FALSE, &MVP[0][0]);
    createRectangle(1,1,0);
    draw3DObject(rectangle);
    laserControl = false;

  }
  // triangle_rotation = -1* (mouseY2);
  if(!cannonLock)
  cannonRotation = atan(triangle_rotation)-(M_PI/2.0f);
  // cannonRotation = atan(temp.Y/(temp.X+4)) - (90 * M_PI/180.0f);
  glm::mat4 triangleTransform = genModelMatrix(cannonPos,cannonRotation,glm::vec3(0.5f,1.0f,1.0f));
  Matrices.model = triangleTransform;
  MVP = VP * Matrices.model; // MVP = p * V * M

  //  Don't change unless you are sure!!
  glUniformMatrix4fv(Matrices.MatrixID, 1, GL_FALSE, &MVP[0][0]);

  // draw3DObject draws the VAO given to it using current MVP matrix
  draw3DObject(trapezium);
  draw3DObject(triangle);

  // draw3DObject(rectangle);

  // draw3DObject(trapezium);
  // Pop matrix to undo transformations till last push matrix instead of recomputing model matrix
  // glPopMatrix ();
  Matrices.model = glm::mat4(1.0f);

  // glm::mat4 translateRectangle = glm::translate (glm::vec3(0, test, 0));        // glTranslatef
  // glm::mat4 rotateRectangle = glm::rotate((float)(rectangle_rotation*M_PI/180.0f), glm::vec3(1,1,1)); // rotate about vector (-1,1,1)
  // Matrices.model *= (translateRectangle * rotateRectangle);
  Matrices.model *= genModelMatrix(cannonPos, M_PI/2, glm::vec3(0.5,0.25,1));
  MVP = VP * Matrices.model;
  glUniformMatrix4fv(Matrices.MatrixID, 1, GL_FALSE, &MVP[0][0]);

  createRectangle(0,0,1);
  // draw3DObject draws the VAO given to it using current MVP matrix
  draw3DObject(rectangle);

  createTrapezium(1,0,0);
  Matrices.model = genModelMatrix(redBucket.T, M_PI, bucketScale);
  MVP = VP * Matrices.model;
  glUniformMatrix4fv(Matrices.MatrixID, 1, GL_FALSE, &MVP[0][0]);
  draw3DObject(trapezium);

  Matrices.model = genModelMatrix(greenBucket.T, M_PI, bucketScale);
  MVP = VP * Matrices.model;
  glUniformMatrix4fv(Matrices.MatrixID, 1, GL_FALSE, &MVP[0][0]);
  createTrapezium(0,1,0);
  draw3DObject(trapezium);

  // Increment angles
  float increments = 1;
//BLOCK LOGIC




  //MIRROR LOGIC
  for (int i = 0; i < vMirror.size(); ++i)
  {
    Matrices.model = genModelMatrix(vMirror[i].T, vMirror[i].R * M_PI/180.0f, mirrorScale);
    MVP = VP * Matrices.model;
    createRectangle(0.3,0.3,0.3);
    glUniformMatrix4fv(Matrices.MatrixID, 1, GL_FALSE, &MVP[0][0]);
    draw3DObject(rectangle);

  }


  //LASER LOGIC
  for(int i=0; i<vLaser.size() ; i++)
  {
    // cout<<vMirror.size()<<endl;
    for(int j=0; j<vMirror.size() ; j++)
    {
      glm::vec3 lT = glm::vec3(vLaser[i].matrix[3]);
      if(checkCollision(lT,vMirror[j].T,0) && vLaser[i].lastCollided != j)
      {
        vLaser[i].lastCollided = j;
        vLaser[i].T =glm::vec3(vLaser[i].matrix[3]);
        // vLaser[i].R = (180.0f - vMirror[j].R + (vLaser[i].R * 180.0f/M_PI)) * M_PI/180.0f;
        float iAngle = -1 * vLaser[i].R * 180.0f/M_PI;
        iAngle = 90 - iAngle;
        float temp = 2 * vMirror[j].R - iAngle - 90;
        // cout<<temp<<endl;
        vLaser[i].R = temp * M_PI/180;
        // vLaser[i].R+=90*M_PI/180.0f;
        vLaser[i].T2.y=0;
        // vLaser[i].R*=-1;

      }
    }


    if(vLaser[i].T2.y > 200)
    {
      vLaser[i].out = true;
      misfires++;
      lives--;
      // cout<<"Laser: "<<vLaser.size()<<endl;
    }
    if(vLaser[i].out || vLaser[i].collideBlock)
    vLaser.erase(vLaser.begin()+ i);
    // if(it->out == true) vLaser.erase(it);
    vLaser[i].matrix = genModelMatrix(vLaser[i].T , vLaser[i].R , vLaser[i].S);
    vLaser[i].matrix *= glm::translate(vLaser[i].T2);
    Matrices.model = vLaser[i].matrix;
    vLaser[i].T2.y+=vLaser[i].speed;
    MVP = VP * Matrices.model;
    createRectangle(0,1,1);
    glUniformMatrix4fv(Matrices.MatrixID, 1, GL_FALSE, &MVP[0][0]);
    draw3DObject(rectangle);



  }



}

/* Initialise glfw window, I/O callbacks and the renderer to use */
/* Nothing to Edit here */
GLFWwindow* initGLFW (int width, int height)
{
    GLFWwindow* window; // window desciptor/handle

    glfwSetErrorCallback(error_callback);
    if (!glfwInit()) {
    }

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    window = glfwCreateWindow(width, height, "Sample OpenGL 3.3 Application", NULL, NULL);

    if (!window) {
        glfwTerminate();
    }

    glfwMakeContextCurrent(window);
    gladLoadGLLoader((GLADloadproc) glfwGetProcAddress);
    glfwSwapInterval( 1 );

    /* --- register callbacks with GLFW --- */

    /* Register function to handle window resizes */
    /* With Retina display on Mac OS X GLFW's FramebufferSize
     is different from WindowSize */
    glfwSetFramebufferSizeCallback(window, reshapeWindow);
    glfwSetWindowSizeCallback(window, reshapeWindow);

    /* Register function to handle window close */
    glfwSetWindowCloseCallback(window, quit);

    /* Register function to handle keyboard input */
    glfwSetKeyCallback(window, keyboard);      // general keyboard input
    glfwSetCharCallback(window, keyboardChar);  // simpler specific character handling

    /* Register function to handle mouse click */
    glfwSetMouseButtonCallback(window, mouseButton);  // mouse button clicks

    return window;
}

/* Initialize the OpenGL rendering properties */
/* Add all the models to be created here */
void initGL (GLFWwindow* window, int width, int height)
{
    /* Objects should be created before any other gl function and shaders */
	// Create the models
	createTriangle (0,0,0); // Generate the VAO, VBOs, vertices data & copy into the array buffer
	createRectangle (0,0,0);
  createTrapezium(1,0,0);

	// Create and compile our GLSL program from the shaders
	programID = LoadShaders( "Sample_GL.vert", "Sample_GL.frag" );
	// Get a handle for our "MVP" uniform
	Matrices.MatrixID = glGetUniformLocation(programID, "MVP");


	reshapeWindow (window, width, height);

    // Background color of the scene
	glClearColor (1.0f, 1.0f, 1.0f, 1.0f); // R, G, B, A
	glClearDepth (1.0f);

	glEnable (GL_DEPTH_TEST);
	glDepthFunc (GL_LEQUAL);

    cout << "VENDOR: " << glGetString(GL_VENDOR) << endl;
    cout << "RENDERER: " << glGetString(GL_RENDERER) << endl;
    cout << "VERSION: " << glGetString(GL_VERSION) << endl;
    cout << "GLSL: " << glGetString(GL_SHADING_LANGUAGE_VERSION) << endl;
}

int main (int argc, char** argv)
{


    GLFWwindow* window = initGLFW(width, height);
    srand(time(NULL));
	initGL (window, width, height);

    double last_update_time = glfwGetTime(), current_time;
    redBucket.T = glm::vec3(-2,-3.12,0);
    greenBucket.T = glm::vec3(2,-3.12,0);
    for(int i=0;i<4;i++)
    {
      mirror temp;
      temp.T = glm::vec3(0,-3,0);
      temp.R = 0.0f;
      vMirror.push_back(temp);
    }
    // cout<<vMirror.size()<<endl;
    vMirror[0].T = glm::vec3(-2,-2,0);
    vMirror[0].R = 0;

    vMirror[1].T = glm::vec3(3,2,0);
    vMirror[1].R = 120;

    vMirror[2].T = glm::vec3(-2,3,0);
    vMirror[2].R = 30;

    vMirror[3].T = glm::vec3(3,-2,0);
    vMirror[3].R = 60;

    // vMirror[0].T = glm::vec3(2,2,1);
    // vMirror[0].R = 60;

    for (int i = 0; i < blockNumber; i++) {
      setBlock(i);
    }

    /* Draw in loop */
    while (!glfwWindowShouldClose(window)) {
        glfwGetCursorPos(window,&mouseX,&mouseY);
        glfwSetScrollCallback(window,scroll_callback);
        mouseCoord = getCoord();
        // mouseX-=width/2;
        // mouseY2= mouseY -height/2;
        // mouseY2/=height/4;
        triangle_rotation =  atan(mouseCoord.Y/(mouseCoord.X+4));
        // else
        // OpenGL Draw commands
        if ((current_time - last_update_time) >= 0.01) { // atleast 0.5s elapsed since last frame

        draw();
      }
        // Swap Frame Buffer in double buffering
        glfwSwapBuffers(window);

        // Poll for Keyboard and mouse events
        glfwPollEvents();
        if(gameOver || lives==0)
        {
          cout<<"Game Over"<<endl;
          cout<<"---STATS--"<<endl;
          cout<<"Your score was "<<score<<endl;
          cout<<"You fired "<<shotsfired<<" shots."<<endl;
          cout<<"You missed "<<misfires<<" shots."<<endl;
          cout<<"You collected wrong bricks "<<wrongcollect<<" times."<<endl;
          quit(window);
        }
        if(score < 0) score = 0;
        if(cannonPos.y > cannonLimit) cannonPos.y = cannonLimit;
        if(cannonPos.y < -cannonLimit) cannonPos.y = -cannonLimit;
        if(redBucket.T.x > bucketLimit) redBucket.T.x = bucketLimit;
        if(redBucket.T.x < -bucketLimit) redBucket.T.x = -bucketLimit;
        if(greenBucket.T.x > bucketLimit) greenBucket.T.x = bucketLimit;
        if(greenBucket.T.x < -bucketLimit) greenBucket.T.x = -bucketLimit;

        if(mouseCoord.X == bufferCoord.X && mouseCoord.Y == bufferCoord.Y)
          cannonLock = true;
        else
          cannonLock = false;
        // Control based on time (Time based transformation like 5 degrees rotation every 0.5s)
        current_time = glfwGetTime(); // Time in seconds
        if ((current_time - last_update_time) >= 1) { // atleast 0.5s elapsed since last frame
            // do something every 0.5 seconds ..
            // cout<<mouseX << ' '<< mouseY << ' '<<atan(triangle_rotation)<<endl;
            bufferCoord = getCoord();
            int temp = rand()%blockNumber;
            vBlock[temp].falling = true;
            vBlock[temp].T +=glm::vec3(0,-45,0);
            // cout<< mouseX << ' ' << mouseY << endl;
            // mouseCoord = getCoord();
            // cout << temp.X << ' ' << temp.Y << endl << endl;
            laserControl = true;
            cout<<"score: "<<score<<endl;
            last_update_time = current_time;
        }

    }

    glfwTerminate();
//    exit(EXIT_SUCCESS);
}
