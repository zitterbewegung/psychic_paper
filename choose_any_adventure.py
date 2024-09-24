!pip install inky[rpi,fonts] transformers torch pillow

from inky.auto import auto
from PIL import Image, ImageDraw, ImageFont
from transformers import pipeline
import os

class AdventureGameEngine:
    def __init__(self, story):
        self.story = story
        self.current_node = self.story['start']
        self.inky_display = auto()  # Automatically detect the Inky display
        self.inky_display.set_border(self.inky_display.WHITE)
        self.font = ImageFont.truetype(inky_display_font(), 22)  # Set the font size
        self.chatbot = pipeline('text-generation', model='apple/OpenELM-270M')  # Load the chatbot model

    def display_current_scene(self):
        node = self.story['nodes'][self.current_node]
        text = node['description']
        choices = node.get('choices', {})
        npc = node.get('npc', None)
        choices_text = "\n".join([f"{key}: {choice['description']}" for key, choice in choices.items()])

        if choices:
            display_text = f"{text}\n\n{choices_text}"
        elif npc:
            display_text = f"{text}\n\nYou encounter {npc['name']}. Type 'talk' to interact."
        else:
            display_text = f"{text}\n\nThe adventure ends here. Thanks for playing!"
        
        self.display_on_screen(display_text)

    def display_on_screen(self, text):
        # Create a new image with the size of the Inky display
        img = Image.new("P", (self.inky_display.WIDTH, self.inky_display.HEIGHT), self.inky_display.WHITE)
        draw = ImageDraw.Draw(img)

        # Draw the text on the image
        draw.multiline_text((10, 10), text, fill=self.inky_display.BLACK, font=self.font, spacing=4)

        # Display the image on the Inky display
        self.inky_display.set_image(img)
        self.inky_display.show()

    def get_player_choice(self):
        node = self.story['nodes'][self.current_node]
        if 'choices' not in node and 'npc' not in node:
            return None

        print("\nChoices or interactions are displayed on the screen. Please type your action in the terminal.")
        choice = input("> ").lower()

        if choice == 'talk' and 'npc' in node:
            self.npc_interaction(node['npc'])
            return self.get_player_choice()  # Allow player to choose again after interaction

        if choice in node.get('choices', {}):
            return choice
        else:
            print("Invalid choice. Please choose a valid option or type 'talk' to interact with NPC.")
            return self.get_player_choice()

    def npc_interaction(self, npc):
        print(f"\nTalking to {npc['name']}...")
        user_input = input("You: ")

        # Generate a response from the NPC using the chatbot model
        response = self.chatbot(f"{npc['name']} says: {user_input}", max_length=50, num_return_sequences=1)
        npc_response = response[0]['generated_text']

        # Display the NPC's response on the screen
        self.display_on_screen(f"{npc['name']} responds:\n\n{npc_response}")

    def move_to_next_node(self, choice):
        self.current_node = self.story['nodes'][self.current_node]['choices'][choice]['next_node']

    def play(self):
        while True:
            self.display_current_scene()
            choice = self.get_player_choice()
            if choice is None:
                break
            self.move_to_next_node(choice)


def inky_display_font():
    # Try to locate a default font
    try:
        font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
        if os.path.exists(font_path):
            return font_path
    except Exception:
        pass
    # Fallback to PIL default font (much less readable)
    return ImageFont.load_default()


# Define the story structure with an NPC
story = {
    "start": "forest_start",
    "nodes": {
        "forest_start": {
            "description": "You are standing in a dark forest. You see a path to the left and right.",
            "choices": {
                "left": {
                    "description": "Take the left path towards the light.",
                    "next_node": "cabin"
                },
                "right": {
                    "description": "Take the right path into the dark.",
                    "next_node": "dark_path"
                }
            }
        },
        "cabin": {
            "description": "You arrive at an old cabin. The door is slightly ajar.",
            "choices": {
                "enter": {
                    "description": "Enter the cabin.",
                    "next_node": "treasure_room"
                },
                "leave": {
                    "description": "Leave the cabin and go back.",
                    "next_node": "forest_start"
                }
            },
            "npc": {
                "name": "Old Hermit",
                "intro": "An old hermit is sitting by the fireplace. He seems to have stories to tell."
            }
        },
        "dark_path": {
            "description": "The dark path leads to a dead end with a strange creature lurking.",
            "choices": {
                "fight": {
                    "description": "Fight the creature.",
                    "next_node": "game_over"
                },
                "flee": {
                    "description": "Run back to the forest start.",
                    "next_node": "forest_start"
                }
            }
        },
        "treasure_room": {
            "description": "You find a treasure chest in the cabin. It could be full of riches or a trap.",
            "choices": {
                "open": {
                    "description": "Open the chest.",
                    "next_node": "win"
                },
                "ignore": {
                    "description": "Leave the chest and exit the cabin.",
                    "next_node": "forest_start"
                }
            }
        },
        "game_over": {
            "description": "You were defeated by the creature. Game Over."
        },
        "win": {
            "description": "Congratulations! You found the treasure and won the game!"
        }
    }
}

# Run the game
if __name__ == "__main__":
    game = AdventureGameEngine(story)
    game.play()
