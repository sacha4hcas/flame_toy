
import random
import pygame
import time
from math import*

SCREEN_WIDTH = 500
SCREEN_HEIGTH = 500
increment_oxygen = 0.2
decrement_fire = 0.08
increment_fire = 0.1 #vitesse de combustion d'une cell avec sa propre oxygen
ratio_perte = 0.3
probability_rule_h = [[0 , 90, 0  ], #probabilite en % d'enflammer son voisin
					 [90, 0 , 90 ],
					 [0 , 5 , 0  ]]
intensity_rule_h = [[0 , 111, 0  ], #puissance de propagation de la combustion si enflammage
					 [50, 0 , 50 ],
					 [0 , 5 , 0  ]]

probability_rule_c = [[0 , 5, 0  ],
					 [50, 0 , 50 ],
					 [0 , 10, 0  ]]

power = 2

class Cell:
	def __init__(o, x, y):
		o.fire = 0
		o.oxygen = 1
		o.x = x
		o.y = y
		o.diff_fire = 0
		o.diff_oxygen = 0
		
	
	def update(o):
		
		if o.fire > 0.2:
			o.diff_oxygen += -o.fire*0.1
		o.diff_oxygen += increment_oxygen
		o.diff_fire += -decrement_fire
		
		if o.oxygen > 0.5:
			d = o.oxygen - 0.5
			if o.fire > 0 or True: #changed this because it is easier to code in the parallelized version
				o.diff_fire += increment_fire*d
		elif o.oxygen < 0.4:
			d = 0.4 - o.oxygen
			o.diff_fire += -decrement_fire*16*d**2

	def resolve_diff(o):
		o.increase_fire(o.diff_fire)
		o.increase_oxygen(o.diff_oxygen)
		
	def clear_diff(o):
		o.diff_fire = 0
		o.diff_oxygen = 0

	def get_pos(o):
		return [o.x, o.y]

	def increase_oxygen(o, value):
		o.oxygen += value
		o.oxygen = max(min(o.oxygen, 1),0)
	
	def increase_fire(o, value):
		o.fire += value
		o.fire = max(min(o.fire, 1),0)

	def interact(o, cell): 
		dx = cell.x - o.x
		dy = cell.y - o.y
		df = o.fire - cell.fire
		
		if df > 0:
			if (random.random() < probability_rule_h[-dy+1][dx+1]/100 * pow(o.fire,power)):
				#rechauffement
				r = random.random()
				cell.diff_fire += df*(1-pow(r,power)) * intensity_rule_h[-dy+1][dx+1]/100
		if df < 0:
			if (random.random() < probability_rule_c[-dy+1][dx+1]/100 * o.fire):
				#refroidissement
				cell.diff_fire += df*random.random()
		

	def getColor(o): 
		if o.fire < 0.9:
			return [o.fire/0.9*255,0,0]
		else:
			return [(-10*o.fire+10)*255,0,(10*o.fire-9)*255]

	def __str__(o):
		return "(" + str(o.oxygen)[0:5] + "," + str(o.fire)[0:5] + ")"

class Sandbox:
	def __init__(o, xsize, ysize):
		o.grid = [[Cell(i, j) for j in range(ysize)] for i in range(xsize)]
		o.diff_grid = [[(0, 0) for j in range(ysize)] for i in range(xsize)]

		o.surface_width = SCREEN_WIDTH / xsize
		o.surface_heigth = SCREEN_HEIGTH / ysize
		o.image_grid = [[pygame.Surface([o.surface_width, o.surface_heigth]) for j in range(ysize)] for i in range(xsize)]

		c = [xsize//2,ysize//5]
		c2 = [xsize//4,ysize//5]
		c3 = [xsize//2 + xsize//4,ysize//5]
		r = 5

		o.firecells = []
		for cells in o.grid:
			for cell in cells:
				if (cell.x-c[0])**2+(cell.y-c[1])**2 < r**2:
					o.firecells.append(cell)
		"""			
		for cells in o.grid:
			for cell in cells:
				if (cell.x-c2[0])**2+(cell.y-c2[1])**2 < r**2:
					o.firecells.append(cell)
		for cells in o.grid:
			for cell in cells:
				if (cell.x-c3[0])**2+(cell.y-c3[1])**2 < r**2:
					o.firecells.append(cell)
		"""
		
		for firecell in o.firecells:
			firecell.fire = 1
		o.ysize = ysize
		o.xsize = xsize
	
	def __str__(o):
		res = ""
		for j in reversed(range(o.ysize)):
			line = ""
			for i in range(o.xsize):
				line += str(o.diff_grid[i][j])
				#line += "(" + str(i) + "," + str(j) + ")"
			res+=line+"\n"
		return res

	def update(o):
		
		for cells in o.grid:
			for cell in cells:
				cell.update()

		
	def interact(o):
		for i in range(o.xsize):
			for j in range(o.ysize):
				if (j+1 < o.ysize):
					a = o.grid[i][j].interact(o.grid[i][j+1])
				if (j-1 > 0):
					a = o.grid[i][j].interact(o.grid[i][j-1])
				if (i+1 < o.xsize):
					a = o.grid[i][j].interact(o.grid[i+1][j])
				if (i-1 >0):
					a = o.grid[i][j].interact(o.grid[i-1][j])

		for cells in o.grid:
			for cell in cells:
				cell.resolve_diff()
			

		for firecell in o.firecells:
			firecell.fire = 1
		
		for i in range(o.xsize):
			for j in range(o.ysize):
				o.image_grid[i][j].fill(o.grid[i][j].getColor())

	def clear_diff(o):
		for cells in o.grid:
			for cell in cells:
				cell.clear_diff()

	def draw(o):
		for j in reversed(range(o.ysize)):
			for i in range(o.xsize):
				cell = o.grid[i][j]
				cell_im = o.image_grid[i][j]
				if (o.grid[i][j].diff_fire != 0 or o.grid[i][j].diff_oxygen != 0):
					o.screen.blit(o.image_grid[i][j],[o.surface_width*i,o.surface_heigth*(o.ysize-cell.y)])



class Run:
	def __init__(o):
		pygame.init()

		sandbox = Sandbox(SCREEN_WIDTH//10,SCREEN_HEIGTH//10)
		screen = pygame.display.set_mode([SCREEN_WIDTH,SCREEN_HEIGTH])
		sandbox.screen = screen


		time_frame = 0.016

		time_fps = time.time()
		frames = 0
		t = time.time()
		running = True
		time_measure = { "update" : [], "interact" : [], "draw" : []}

		while running:
			if (time.time() - time_fps >= 1):
				print(frames)
				#print(time_measure)
				frames = 0
				time_fps = time.time()

			if True:
				t = time.time()


		
				timer = time.time()
				sandbox.update()
				time_measure["update"].append(time.time() - timer)

				timer = time.time()
				sandbox.interact()
				time_measure["interact"].append(time.time() - timer)

				timer = time.time()
				sandbox.draw()
				time_measure["draw"].append(time.time() - timer)

				sandbox.clear_diff()
				#print(sandbox)
				pygame.display.update()
				frames+=1

			for event in pygame.event.get():
				if event.type == pygame.QUIT:
					print(time_measure)
					running = False
	

		pygame.quit()