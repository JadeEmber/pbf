#include "common.h"
#include "Simulation.h"
#include "FullscreenQuad.h"

/** \file main.cpp
 * Main source file.
 * The source file that contains the main entry point and performs initialization and cleanup.
 */

/** GLFW window.
 * The GLFW window.
 */
GLFWwindow *window = NULL;
/** Simulation class.
 * The global Simulation object.
 */
Simulation *simulation = NULL;

/** GLFW error callback.
 * Outputs error messages from GLFW.
 * \param error error id
 * \param msg error message
 */
void glfwErrorCallback (int error, const char *msg)
{
    std::cerr << "GLFW error: " << msg << std::endl;
}

/** OpenGL debug callback.
 * Outputs a debug message from OpenGL.
 * \param source source of the debug message
 * \param type type of the debug message
 * \param id debug message id
 * \param severity severity of the debug message
 * \param length length of the debug message
 * \param message debug message
 * \param userParam user pointer
 *
 */
void glDebugCallback (GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length,
        const GLchar *message, const void *userParam)
{
    std::cerr << "OpenGL debug message: " << std::string (message, length) << std::endl;
}

/** Cursor position.
 * Stores the last known cursor position. Used to calculate relative cursor movement.
 */
glm::dvec2 cursor;

/** Mouse movement callback.
 * GLFW callback for mouse movement events. Passes the event to the Simulation class.
 * \param window GLFW window that produced the event
 * \param x new x coordinate of the cursor
 * \param y new y coordinate of the cursor
 */
void OnMouseMove (GLFWwindow *window, double x, double y)
{
    Simulation *simulation = reinterpret_cast<Simulation*> (glfwGetWindowUserPointer (window));
    simulation->OnMouseMove (x - cursor.x, y - cursor.y);
    cursor.x = x; cursor.y = y;
}

/** Mouse button callback.
 * GLFW callback for mouse button events. Passes the event to the Simulation class.
 * \param window GLFW window that produced the event
 * \param button the mouse button that was pressed or released
 * \param action one of GLFW_PRESS or GLFW_RELEASE
 * \param mode bit field describing which modifier keys were hold down
 */
void OnMouseButton (GLFWwindow *window, int button, int action, int mods)
{
    Simulation *simulation = reinterpret_cast<Simulation*> (glfwGetWindowUserPointer (window));
    if (action == GLFW_PRESS)
    	simulation->OnMouseDown (button);
    else if (action == GLFW_RELEASE)
    	simulation->OnMouseUp (button);
}

/** Key event callback.
 * GLFW callback for key events. Passes the event to the Simulation class.
 * \param window GLFW window that produced the event
 * \param key the key that was pressed or released
 * \param scancode system-specific scancode of the key
 * \param action GLFW_PRESS, GLFW_RELEASE or GLFW_REPEAT
 * \param mods Bit-field describing the modifier keys that were held down when the event ocurred
 */
void OnKeyEvent (GLFWwindow *window, int key, int scancode, int action, int mods)
{
    Simulation *simulation = reinterpret_cast<Simulation*> (glfwGetWindowUserPointer (window));
    if (action == GLFW_RELEASE)
        simulation->OnKeyUp (key);
    else if (action == GLFW_PRESS)
        simulation->OnKeyDown (key);
}

/** Window resize callback.
 * GLFW callback for window resize events. Passes the event to the Simulation class.
 * \param window GLFW window that was resized
 * \param width new window width
 * \param height new window height
 */
void OnResize (GLFWwindow *window, int width, int height)
{
    Simulation *simulation = reinterpret_cast<Simulation*> (glfwGetWindowUserPointer (window));
    simulation->Resize (width, height);
}

/** Inialization.
 * Perform general initialization tasks.
 */
void initialize (void)
{
    // set GLFW error callback
    glfwSetErrorCallback (glfwErrorCallback);

    // specify parameters for the opengl context
    glfwWindowHint (GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint (GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint (GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint (GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint (GLFW_OPENGL_DEBUG_CONTEXT, GL_TRUE);

    // open a window and an OpenGL context
    window = glfwCreateWindow (1280, 720, "PBF", NULL, NULL);
    if (window == NULL)
        throw std::runtime_error ("Cannot open window.");
    glfwMakeContextCurrent (window);

    // get OpenGL entry points
    glcorewInit ((glcorewGetProcAddressCallback) glfwGetProcAddress);

    glDebugMessageCallback (glDebugCallback, NULL);
    glEnable (GL_DEBUG_OUTPUT);

    // create the simulation class
    simulation = new Simulation ();

    // setup event callbacks
    glfwSetWindowUserPointer (window, simulation);
    glfwGetCursorPos (window, &cursor.x, &cursor.y);
    glfwSetCursorPosCallback (window, OnMouseMove);
    glfwSetMouseButtonCallback (window, OnMouseButton);
    glfwSetKeyCallback (window, OnKeyEvent);
    glfwSetFramebufferSizeCallback (window, OnResize);

    // notify the Simulation class of the initial window dimensions
    int width, height;
    glfwGetFramebufferSize (window, &width, &height);
    simulation->Resize (width, height);
}

/** Cleanup.
 */
void cleanup (void)
{
	// release simulation class
    if (simulation != NULL)
        delete simulation;
    // release signleton classes
    FullscreenQuad::Release ();
    // destroy window and shutdown glfw
    if (window != NULL)
        glfwDestroyWindow (window);
    glfwTerminate ();
}

/** Main.
 * Main entry point.
 * \param argc number of arguments
 * \param argv argument array
 * \returns error code
 */
int main (int argc, char *argv[])
{
    // initialize GLFW
    if (!glfwInit ())
    {
        std::cerr << "Cannot initialize GLFW." << std::endl;
        return -1;
    }

    try {
        // initialization
        initialize ();

        // simulation loop
        while (!glfwWindowShouldClose (window))
        {
            if (!simulation->Frame ())
                break;

            glfwSwapBuffers (window);
            glfwPollEvents ();
        }

        // cleanup
        cleanup ();
        return 0;
    } catch (std::exception &e) {
        cleanup ();
        std::cerr << "Exception: " << e.what () << std::endl;
        return -1;
    }
}
