class_name IconSvgPack
extends RefCounted

## 《玉简问道》全套国风双色线性 SVG 图标库（50 枚）
## 规范：48x48 视口，兼容 Godot 4 ThorVG，占位符 {C1}=主线条色，{C2}=点缀/微光色

const TEMPLATES: Dictionary = {
	# ==================== 1. 底部导航与通用 UI (7) ====================
	"default_jade": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="14" y="8" width="20" height="32" rx="3" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.14"/>
		<path d="M20 8 L20 5 L28 5 L28 8" stroke="{C2}" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M19 16 L29 16 M19 22 L29 22 M19 28 L25 28" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<circle cx="27" cy="33" r="2.2" fill="{C2}"/>
	</svg>""",

	"nav_craft": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M13 21 C12 30 17 35 24 35 C31 35 36 30 35 21 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M10 21 L38 21" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M16 21 C17 15 20 13 24 13 C28 13 31 15 32 21" stroke="{C1}" stroke-width="2.2"/>
		<circle cx="24" cy="10" r="2.2" stroke="{C2}" stroke-width="2.0"/>
		<path d="M17 34 L14 40 M31 34 L34 40" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 25 C26.5 27.5 26.5 30 24 31 C21.5 30 21.5 27.5 24 25 Z" fill="{C2}"/>
	</svg>""",

	"nav_farm": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 33 L24 17" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 26 C16 25 13 19 15 13 C20 13 24 18 24 24" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.2"/>
		<path d="M24 23 C32 22 35 16 33 10 C28 10 24 15 24 21" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.2"/>
		<path d="M9 36 Q24 30 39 36" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M13 41 Q24 36 35 41" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	"nav_combat": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M38 10 L35 17 L18 34 L14 30 L31 13 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M10 10 L13 17 L30 34 L34 30 L17 13 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M11 28 L20 37 M15 33 L10 38" stroke="{C2}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M37 28 L28 37 M33 33 L38 38" stroke="{C2}" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"nav_dao_bold": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="14" r="6" fill="{C1}"/>
		<path d="M20.5 8.5 C22 5.5 26 5.5 27.5 8.5" stroke="{C1}" stroke-width="2.6" stroke-linecap="round"/>
		<path d="M11 38 C11 27 16.5 22 24 22 C31.5 22 37 27 37 38 Z" fill="{C1}" fill-opacity="0.88" stroke="{C1}" stroke-width="2.4" stroke-linejoin="round"/>
		<path d="M8 40 C15 36.5 33 36.5 40 40" stroke="{C1}" stroke-width="3.2" stroke-linecap="round"/>
	</svg>""",

	"nav_shop": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M7 20 Q24 12 41 20 L36 22 L12 22 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.18"/>
		<path d="M13 14 Q24 8 35 14" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M14 22 L14 38 M34 22 L34 38 M9 38 L39 38" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<circle cx="24" cy="30" r="4.5" stroke="{C2}" stroke-width="2.0"/>
		<rect x="22.5" y="28.5" width="3" height="3" fill="{C2}"/>
	</svg>""",

	"nav_bag": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M18 16 C12 21 11 31 15 37 C18 40 30 40 33 37 C37 31 36 21 30 16 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M19 16 L16 10 L21 12 L24 9 L27 12 L32 10 L29 16" stroke="{C1}" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M17 17 L31 17" stroke="{C2}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M24 17 L28 23 M24 17 L21 22" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<circle cx="24" cy="29" r="3" stroke="{C2}" stroke-width="1.8"/>
	</svg>""",

	"ui_bounty": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M14 10 L34 10 L34 20 C34 30 29 36 24 39 C19 36 14 30 14 20 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.14"/>
		<path d="M14 15 L9 12 L10 22 L14 20" stroke="{C2}" stroke-width="2.0" stroke-linejoin="round"/>
		<path d="M34 15 L39 12 L38 22 L34 20" stroke="{C2}" stroke-width="2.0" stroke-linejoin="round"/>
		<path d="M20 20 L28 20 M24 20 L24 30" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<circle cx="24" cy="33" r="1.8" fill="{C2}"/>
	</svg>""",

	"ui_scripture": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="10" y="8" width="28" height="32" rx="2" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.12"/>
		<path d="M15 8 L15 40 M33 8 L33 40" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M19 18 L29 18 M19 24 L29 24 M19 30 L25 30" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M10 12 L6 10 L6 38 L10 36" stroke="{C2}" stroke-width="2.0" stroke-linejoin="round"/>
	</svg>""",

	"ui_help": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="15.5" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.10"/>
		<path d="M19 19 C19 15.8 21.2 13.8 24 13.8 C27 13.8 29 15.8 29 18.6 C29 21.4 26.4 22.6 24.9 24 C24.2 24.7 24 25.4 24 26.6" stroke="{C1}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>
		<circle cx="24" cy="30.8" r="1.9" fill="{C2}"/>
	</svg>""",

	"ui_dao_body": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="14" r="5" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.22"/>
		<path d="M21 9 C22 6.5 26 6.5 27 9" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M13 36 C13 27 17.5 22 24 22 C30.5 22 35 27 35 36" stroke="{C1}" stroke-width="2.2" stroke-linecap="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M10 38 C16 35 32 35 38 38" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
		<circle cx="24" cy="29" r="2.2" fill="{C2}"/>
	</svg>""",

	"ui_slot_weapon": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M35 11 L18 28 L20 30 L37 13 L37 11 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.14"/>
		<path d="M14 25 L23 34" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M17 31 L11 37" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"ui_slot_armor": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M18 11 L11 17 L14 23 L17 21 L16 37 L32 37 L31 21 L34 23 L37 17 L30 11 L24 16 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.14"/>
		<path d="M17 26 L31 26" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"ui_slot_natal": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="14" stroke="{C2}" stroke-width="1.6" stroke-dasharray="4 3" fill="none"/>
		<circle cx="24" cy="22" r="6.5" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.24"/>
		<path d="M13 32 C17 29 21 30 24 34 C27 30 31 29 35 32 C31 36 27 37 24 37 C21 37 17 36 13 32 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="{C2}" fill-opacity="0.20"/>
	</svg>""",

	"natal_qingzhu_sword": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M37 8 L17 28 L20 31 L40 11 L40 8 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.26"/>
		<path d="M22 26 L36 12" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M13 24 L24 35" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M16 32 L10 38" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M12 15 C15 11 20 11 22 14 C19 17 15 17 12 15 Z" stroke="{C2}" stroke-width="1.8" stroke-linejoin="round" fill="{C2}" fill-opacity="0.26"/>
		<path d="M29 33 C32 30 36 30 38 33 C35 36 31 36 29 33 Z" stroke="{C2}" stroke-width="1.8" stroke-linejoin="round" fill="{C2}" fill-opacity="0.26"/>
	</svg>""",

	"natal_xuantian_bell": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M20 9 C20 6.5 28 6.5 28 9" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M16 14 C16 10 32 10 32 14 L36 34 L12 34 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.20"/>
		<ellipse cx="24" cy="34" rx="12" ry="3.2" stroke="{C1}" stroke-width="2.0" fill="{C2}" fill-opacity="0.28"/>
		<path d="M15 23 L33 23 M17 18 L31 18" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
		<circle cx="24" cy="36.5" r="2.2" fill="{C1}"/>
	</svg>""",

	"natal_zhangtian_ding": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M13 17 C13 13 35 13 35 17 L33 30 C32.5 34 28.5 36 24 36 C19.5 36 15.5 34 15 30 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.22"/>
		<path d="M13 18 C9.5 18 9.5 23 13.5 23 M35 18 C38.5 18 38.5 23 34.5 23" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M17 35 L15 40 M31 35 L33 40 M24 36 L24 40" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<circle cx="24" cy="24.5" r="3.5" stroke="{C2}" stroke-width="1.8" fill="{C2}" fill-opacity="0.28"/>
		<path d="M24 8 L24 11 M19 9.5 L20.5 11.5 M29 9.5 L27.5 11.5" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"ui_natal_rune": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<polygon points="24,8 38,24 24,40 10,24" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<polygon points="24,14 32,24 24,34 16,24" stroke="{C2}" stroke-width="1.8" stroke-linejoin="round" fill="{C2}" fill-opacity="0.22"/>
		<circle cx="24" cy="24" r="2.6" fill="{C1}"/>
	</svg>""",

	"root_metal": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="15" stroke="{C2}" stroke-width="1.5" stroke-opacity="0.65" fill="{C2}" fill-opacity="0.10"/>
		<polygon points="24,9 31,24 24,39 17,24" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.26"/>
		<path d="M24 14 L24 34 M19.5 24 L28.5 24" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	"root_wood": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="15" stroke="{C2}" stroke-width="1.5" stroke-opacity="0.65" fill="{C2}" fill-opacity="0.10"/>
		<path d="M24 36 L24 17 M18 36 C21 33 27 33 30 36" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M24 28 C17 26.5 15.5 21 19 18 C22.5 19.5 24 22.5 24 26" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.28"/>
		<path d="M24 23 C31 21.5 32.5 16 29 13 C25.5 14.5 24 17.5 24 21" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.28"/>
	</svg>""",

	"root_water": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="15" stroke="{C2}" stroke-width="1.5" stroke-opacity="0.65" fill="{C2}" fill-opacity="0.10"/>
		<path d="M24 11 C24 11 15 22 15 27.5 C15 32.5 19 36.5 24 36.5 C29 36.5 33 32.5 33 27.5 C33 22 24 11 24 11 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
		<path d="M19.5 28 C20 31 22 32.5 24.5 33" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	"root_fire": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="15" stroke="{C2}" stroke-width="1.5" stroke-opacity="0.65" fill="{C2}" fill-opacity="0.10"/>
		<path d="M24 11 C29 17 32 21.5 32 26.5 C32 31.2 28.4 35 24 35 C19.6 35 16 31.2 16 26.5 C16 23 18 20 20.5 18 C20.2 21 21.8 22.8 23 22.8 C22.5 19 22.8 15 24 11 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.28"/>
		<circle cx="24" cy="28.5" r="2.2" fill="{C1}"/>
	</svg>""",

	"root_earth": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="15" stroke="{C2}" stroke-width="1.5" stroke-opacity="0.65" fill="{C2}" fill-opacity="0.10"/>
		<path d="M13 32 L21 17 L26.5 26.5 L30 21 L35 32 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.26"/>
		<path d="M14 35.5 L34 35.5" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	"law_metal": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 6 L28 13 L26.8 30 L21.2 30 L20 13 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.26"/>
		<path d="M24 10 L24 29" stroke="{C1}" stroke-width="1.5" stroke-linecap="round"/>
		<path d="M14 30 C18 32 30 32 34 30" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M24 31 L24 40" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<circle cx="24" cy="41.5" r="2.0" fill="{C2}" stroke="{C1}" stroke-width="1.5"/>
		<path d="M9 17 L15 21 L9 25 M39 17 L33 21 L39 25" stroke="{C2}" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	"law_wood": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 39 L24 16" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M13 40 C17 36.5 21 36.5 24 39 C27 36.5 31 36.5 35 40" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M24 7 C29 11 29 16.5 24 20 C19 16.5 19 11 24 7 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.28"/>
		<path d="M24 26 C14 25 10 19 13 14.5 C18 15.5 22 19.5 24 26 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
		<path d="M24 24 C34 23 38 17 35 12.5 C30 13.5 26 17.5 24 24 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
		<circle cx="14" cy="31" r="1.8" fill="{C2}"/>
		<circle cx="34" cy="30" r="1.8" fill="{C2}"/>
	</svg>""",

	"law_water": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M8 32 C10 18 20 11 31 14 C37 15.8 39 21.5 35.5 25.5 C32.5 28.8 27 28 26 24 C25.2 21 27.8 19 30 20.5" stroke="{C1}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M12 32 C15 24 21 20 27 21 C24 26 25 31 32 32" stroke="{C2}" stroke-width="1.8" stroke-linecap="round" fill="{C2}" fill-opacity="0.22"/>
		<path d="M8 38 C14 34.5 20 38.5 26 35.5 C32 32.5 37 36.5 41 34" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<circle cx="13" cy="14" r="2.0" fill="{C2}"/>
		<circle cx="38" cy="12" r="1.8" fill="{C2}"/>
		<circle cx="20" cy="28" r="1.6" fill="{C2}"/>
	</svg>""",

	"law_fire": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 7 C29 14 32.5 18 32.5 24 C35 21 37.5 22.5 37.5 27.5 C37.5 34.5 31.8 40 24 40 C16.2 40 10.5 34.5 10.5 27.5 C10.5 22.5 13 21 15.5 24 C15.5 18 19 14 24 7 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.22"/>
		<path d="M24 19 C27 23.5 29 27 29 31 C29 34.2 26.8 36.5 24 36.5 C21.2 36.5 19 34.2 19 31 C19 27 21 23.5 24 19 Z" stroke="{C2}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.32"/>
		<circle cx="13" cy="14" r="1.8" fill="{C2}"/>
		<circle cx="35" cy="14" r="1.8" fill="{C2}"/>
	</svg>""",

	"law_earth": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M13 35 L24 10 L35 35 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.26"/>
		<path d="M24 10 L21.5 22 L25.5 27 L23.5 35" stroke="{C1}" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M6 35 L15 20 L20 31 M28 31 L33 20 L42 35" stroke="{C1}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M7 39 L41 39" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M9 28 C13 26.5 17 29 21 27.5" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"ui_fishing_rod": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M9 36 C16 25 24 16 36 10" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M36 10 L36 27" stroke="{C2}" stroke-width="1.5" stroke-linecap="round"/>
		<path d="M32 30 C35 28 38 28 40 31 C38 34 35 34 32 30 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="{C2}" fill-opacity="0.28"/>
		<path d="M10 40 C16 37 22 37 28 40 C33 42 38 41 41 39" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"ui_five_elements": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="16" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.12"/>
		<circle cx="24" cy="24" r="7" stroke="{C1}" stroke-width="1.8" fill="{C2}" fill-opacity="0.20"/>
		<path d="M24 8 L28.8 18.5 L40 18.5 L31 25.5 L34.5 36.5 L24 30 L13.5 36.5 L17 25.5 L8 18.5 L19.2 18.5 Z" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round"/>
		<circle cx="24" cy="8" r="2.4" fill="{C2}"/>
		<circle cx="40" cy="18.5" r="2.4" fill="{C2}"/>
		<circle cx="34.5" cy="36.5" r="2.4" fill="{C2}"/>
		<circle cx="13.5" cy="36.5" r="2.4" fill="{C2}"/>
		<circle cx="8" cy="18.5" r="2.4" fill="{C2}"/>
	</svg>""",

	"ui_mail_seal": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M8 13 L40 13 L40 35 L8 35 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.18"/>
		<path d="M9 15 L24 26 L39 15" stroke="{C1}" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M9 33 L19 24 M39 33 L29 24" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
		<circle cx="35" cy="30" r="4.5" stroke="{C1}" stroke-width="1.6" fill="{C2}" fill-opacity="0.34"/>
	</svg>""",

	"ui_technique_scroll": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M12 11 L36 11 L36 37 L12 37 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M9 11 C13 9 13 13 17 11 L17 37 C13 39 13 35 9 37 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
		<path d="M39 11 C35 9 35 13 31 11 L31 37 C35 39 35 35 39 37 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
		<path d="M21 18 L27 18 M21 24 L27 24 M21 30 L27 30" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"ui_tea_pot": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<ellipse cx="23" cy="28" rx="11" ry="9" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.20"/>
		<path d="M17 20 C17 16 29 16 29 20" stroke="{C1}" stroke-width="2.0"/>
		<circle cx="23" cy="15" r="2" fill="{C2}" stroke="{C1}" stroke-width="1.5"/>
		<path d="M34 25 C39 24 40 30 34 31" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M12 27 L7 21" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M19 10 C18 8 20 6 19 4 M27 10 C26 8 28 6 27 4" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	"tea_wudao": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M12 22 L36 22 C35 31 30.5 36 24 36 C17.5 36 13 31 12 22 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.20"/>
		<path d="M17 36 L31 36" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M24 19 C21 16 21 12 24 9 C27 12 27 16 24 19 Z" stroke="{C2}" stroke-width="1.8" stroke-linejoin="round" fill="{C2}" fill-opacity="0.28"/>
		<path d="M18 16 C16.5 14 17.5 11.5 16.5 9.5 M30 16 C31.5 14 30.5 11.5 31.5 9.5" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	"tea_ningshen": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M11 22 L37 22 C36 30 31 35 24 35 C17 35 12 30 11 22 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.18"/>
		<path d="M13 18 C16 14 32 14 35 18 L13 18 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.26"/>
		<circle cx="24" cy="12" r="2.2" stroke="{C1}" stroke-width="1.8" fill="{C2}" fill-opacity="0.30"/>
		<path d="M14 38 L34 38" stroke="{C2}" stroke-width="2.2" stroke-linecap="round"/>
		<circle cx="24" cy="28" r="2.2" fill="{C2}"/>
	</svg>""",

	"tea_poe": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M13 24 L35 24 L32 36 L16 36 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.20"/>
		<path d="M17 39 L31 39" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 7 L27 17 L24 21 L21 17 Z" stroke="{C2}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.30"/>
		<path d="M17 15 L20 20 M31 15 L28 20" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"tea_fish_soup": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<ellipse cx="24" cy="29" rx="13" ry="9" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.20"/>
		<path d="M11 27 C8 27 8 31 11 31 M37 27 C40 27 40 31 37 31" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M17 29 C20 25.5 26 25.5 29 29 C26 32.5 20 32.5 17 29 Z" stroke="{C2}" stroke-width="1.8" stroke-linejoin="round" fill="{C2}" fill-opacity="0.30"/>
		<polygon points="29,29 33,26.5 33,31.5" fill="{C2}"/>
		<path d="M18 16 C17 13 19 11 18 8 M24 15 C23 12 25 10 24 7 M30 16 C29 13 31 11 30 8" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	"ui_leaderboard_scroll": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="11" y="9" width="26" height="30" rx="3" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.16"/>
		<path d="M16 17 L32 17 M16 23 L29 23 M16 29 L26 29" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M9 12 L11 12 M9 36 L11 36 M37 12 L39 12 M37 36 L39 36" stroke="{C2}" stroke-width="2.2" stroke-linecap="round"/>
		<circle cx="31" cy="30" r="2.2" fill="{C2}"/>
	</svg>""",

	"item_spirit_dew": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 9 C24 9 13 22 13 29 C13 35.1 17.9 40 24 40 C30.1 40 35 35.1 35 29 C35 22 24 9 24 9 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
		<path d="M19 29 C19 32.5 21.5 34.5 24 35" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	"item_spirit_nectar": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M19 9 L29 9 L27 15 L21 15 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
		<path d="M18 16 Q13 20 13 27 Q13 37 24 37 Q35 37 35 27 Q35 20 30 16 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.10"/>
		<path d="M24 19 C26.5 22.5 26.5 26 24 29 C21.5 26 21.5 22.5 24 19 Z" fill="{C2}" fill-opacity="0.55"/>
		<path d="M10 23 C8 27 8 32 10 36" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M38 23 C40 27 40 32 38 36" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<circle cx="24" cy="33" r="1.6" fill="{C2}"/>
	</svg>""",

	"item_spirit_fish": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M12 24 C17 16 27 16 33 24 C27 32 17 32 12 24 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.22"/>
		<polygon points="33,24 40,18 40,30" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.26"/>
		<circle cx="17" cy="23" r="1.6" fill="{C1}"/>
		<path d="M21 20 C23 22 23 26 21 28" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	"ui_jump": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M12 24 L30 24 M23 17 L30 24 L23 31" stroke="{C1}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M36 13 L36 35" stroke="{C2}" stroke-width="2.4" stroke-linecap="round"/>
	</svg>""",

	"ui_stop": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="11" y="11" width="26" height="26" rx="5" stroke="{C1}" stroke-width="2.3" fill="{C2}" fill-opacity="0.12"/>
		<rect x="18" y="18" width="12" height="12" rx="2.5" fill="{C2}"/>
	</svg>""",

	"tech_wood": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 41 L24 18" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 24 C16 23 12 17 14 11 C20 11 24 16 24 22" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.2"/>
		<path d="M24 21 C32 20 36 14 34 8 C28 8 24 13 24 19" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.2"/>
		<path d="M24 12 C21 9 22 6 24 5 C26 6 27 9 24 12 Z" stroke="{C2}" stroke-width="2.0" fill="{C2}" fill-opacity="0.3"/>
	</svg>""",

	"tech_sword": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M38 9 L34 18 L20 32 L15 27 L29 13 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M10 9 L14 18 L28 32 L33 27 L19 13 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M17 6 L19 10 L24 8 L29 10 L31 6" stroke="{C2}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
		<circle cx="24" cy="42" r="2.2" fill="{C2}"/>
	</svg>""",

	"tech_shield": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="16" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.12"/>
		<path d="M24 8 C31 8 36 13 36 20 C36 29 30 35 24 38 C18 35 12 29 12 20 C12 13 17 8 24 8 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M24 14 L24 32 M18 20 L30 20" stroke="{C2}" stroke-width="2.2" stroke-linecap="round"/>
		<circle cx="24" cy="20" r="2.4" fill="{C1}"/>
	</svg>""",

	"ui_codex": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 9 C19 6 13 6 9 8 L9 38 C13 36 19 36 24 39 C29 36 35 36 39 38 L39 8 C35 6 29 6 24 9 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.12"/>
		<path d="M24 9 L24 39" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M13 16 L19 16 M29 16 L35 16 M13 22 L19 22 M29 22 L35 22" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<circle cx="24" cy="26" r="2.4" fill="{C2}"/>
	</svg>""",

	"ui_tower": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M22 5 L26 5 L26 10 L22 10 Z" stroke="{C2}" stroke-width="2.0" stroke-linejoin="round"/>
		<path d="M16 10 L32 10 L32 16 L16 16 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.14"/>
		<path d="M13 16 L35 16 L35 24 L13 24 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.14"/>
		<path d="M10 24 L38 24 L38 34 L10 34 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.14"/>
		<path d="M8 34 L40 34 L40 41 L8 41 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.14"/>
		<path d="M20 20 L28 20 M18 29 L30 29 M16 37 L32 37" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M9 41 L39 41" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"enemy_thunder_serpent": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 33 11 C 21 8 11 15 13 23.5 C 14.8 30 33 27 33 34 C 33 39.5 22 41.5 14 39" fill="none" stroke="{C1}" stroke-width="5.2" stroke-linecap="round" stroke-opacity="0.22"/>
	  <path d="M 33 11 C 21 8 11 15 13 23.5 C 14.8 30 33 27 33 34 C 33 39.5 22 41.5 14 39" fill="none" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
	  <polygon points="31,8.5 39,10.5 35.5,15.5 29.5,13.5" fill="{C1}" fill-opacity="0.28" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 31.5 9 L 28 5 M 11.5 18 L 8 16.5 M 35 31.5 L 38.5 30" fill="none" stroke="{C1}" stroke-width="1.7" stroke-linecap="round"/>
	  <circle cx="34.2" cy="11.5" r="1.4" fill="{C2}"/>
	  <path d="M 10 9.5 L 16.5 9.5 L 13 15.5 L 18 15.5 L 10.5 25" fill="none" stroke="{C2}" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/>
	  <path d="M 38 22 L 34 27 L 37.5 27.5 L 33.5 33" fill="none" stroke="{C2}" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	"enemy_taixu_beast": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 11 36 L 7.5 26.5 L 12.5 22 L 10 13.5 L 18.5 16.5 L 24 6.5 L 29.5 16.5 L 38 13.5 L 35.5 22 L 40.5 26.5 L 37 36 L 30 39.5 L 18 39.5 Z" fill="{C1}" fill-opacity="0.20" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <polygon points="24,5 26.6,16.5 21.4,16.5" fill="{C2}" fill-opacity="0.72" stroke="{C1}" stroke-width="1.7" stroke-linejoin="round"/>
	  <path d="M 16.5 21.5 L 22 24 M 31.5 21.5 L 26 24" fill="none" stroke="{C2}" stroke-width="2.2" stroke-linecap="round"/>
	  <path d="M 18 31.5 L 20.2 28.5 L 24 31.5 L 27.8 28.5 L 30 31.5" fill="none" stroke="{C1}" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/>
	  <path d="M 14 35.5 L 18 33.5 M 34 35.5 L 30 33.5 M 10 19 L 13 21 M 38 19 L 35 21" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	"enemy_dragon_remnant": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="24" r="20.2" fill="none" stroke="{C1}" stroke-width="1.4" stroke-opacity="0.38" stroke-dasharray="14 6"/>
	  <path d="M 18.5 13.8 Q 10.5 9.5 8 3.5 M 13.8 10 L 14.5 4.2 M 10.8 7.6 L 6.2 8.5 M 29.5 13.8 Q 37.5 9.5 40 3.5 M 34.2 10 L 33.5 4.2 M 37.2 7.6 L 41.8 8.5" fill="none" stroke="{C1}" stroke-width="2.1" stroke-linecap="round"/>
	  <path d="M 15.5 15 L 11 19 L 14 23.5 L 11.5 27.5 L 17 31 L 19.5 36.5 L 24 38 L 28.5 36.5 L 31 31 L 36.5 27.5 L 34 23.5 L 37 19 L 32.5 15 L 24 12.2 Z" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 17.5 20 L 22 21.8 M 30.5 20 L 26 21.8" fill="none" stroke="{C2}" stroke-width="2.3" stroke-linecap="round"/>
	  <path d="M 24 15.5 L 24 26.5 M 19.5 28.5 L 21 32 L 24 29.5 L 27 32 L 28.5 28.5" fill="none" stroke="{C1}" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
	  <path d="M 15.5 27.5 C 9.5 27 6.5 31 4.5 35.5 M 32.5 27.5 C 38.5 27 41.5 31 43.5 35.5" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <path d="M 8 15 L 11.5 15 L 9 19.5 L 12 20 L 8 24.5 M 40 15 L 36.5 15 L 39 19.5 L 36 20 L 40 24.5" fill="none" stroke="{C2}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
	  <path d="M 12 42 Q 16 39 20 41.5 Q 24 39 28 41.5 Q 32 39 36 42" fill="none" stroke="{C2}" stroke-width="1.7" stroke-linecap="round"/>
	</svg>""",

	"ui_tribulation": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M13 21 C9 21 8 15 12 13 C13 8 21 7 25 10 C29 7 37 10 36 16 C40 17 39 22 34 22" stroke="{C1}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" fill="{C2}" fill-opacity="0.12"/>
		<path d="M26 17 L18 28 L25 28 L20 41 L32 25 L25 25 Z" stroke="{C2}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.28"/>
	</svg>""",

	# ==================== 2. 八大核心技能 (8) ====================
	"skill_herbalism": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
		<path d="M 11 23 C 11 13 37 13 37 23 C 37 26.5 31 27.5 24 27.5 C 17 27.5 11 26.5 11 23 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
		<path d="M 15.5 21.5 C 18 17.5 30 17.5 32.5 21.5" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M 24 27.5 Q 23.5 34.5 21 41" fill="none" stroke="{C1}" stroke-width="2.5" stroke-linecap="round"/>
		<path d="M 23.2 35 Q 28.5 34.5 32 30.5 Q 27.5 29.5 23.2 35 Z" fill="{C2}" fill-opacity="0.35" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round"/>
		<path d="M 36.5 8.5 Q 39.5 12.5 36.5 15 Q 33.5 12.5 36.5 8.5 Z" fill="{C2}" fill-opacity="0.85"/>
		<circle cx="13.5" cy="11.5" r="1.5" fill="{C2}"/>
	</svg>""",

	"skill_woodcutting": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
		<path d="M 13 37 L 34 11" fill="none" stroke="{C1}" stroke-width="2.8" stroke-linecap="round"/>
		<path d="M 24 14 L 35 16 C 37.5 21 36.5 26.5 33 30 L 22 22 Z" fill="{C1}" fill-opacity="0.2" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
		<path d="M 33.5 17.2 C 35.5 21 34.8 25.5 32 28.5" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<ellipse cx="18" cy="36.5" rx="8.5" ry="3.5" fill="{C2}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.0"/>
		<path d="M 9.5 36.5 L 10.5 41.5 Q 18 43.5 25.5 41.5 L 26.5 36.5" fill="none" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
		<ellipse cx="18" cy="36.5" rx="4.2" ry="1.6" fill="none" stroke="{C2}" stroke-width="1.3"/>
	</svg>""",

	"skill_mining": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
		<path d="M 14 36 L 31 15" fill="none" stroke="{C1}" stroke-width="2.6" stroke-linecap="round"/>
		<path d="M 17 12 Q 28 11 38 22 Q 30 16.5 25 17.5 Q 21 15 17 12 Z" fill="{C1}" fill-opacity="0.24" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
		<polygon points="24,39 27,27 32,24 35,29 33,39" fill="{C2}" fill-opacity="0.3" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
		<polygon points="32,39 35,30 39.5,31.5 38.5,39" fill="{C2}" fill-opacity="0.2" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
		<path d="M 30.5 26.5 L 30.5 37.5" fill="none" stroke="{C2}" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M 12 19 L 12 24 M 9.5 21.5 L 14.5 21.5" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	"skill_alchemy": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
		<path d="M 17 18 L 31 18 L 29 14.5 L 19 14.5 Z" fill="{C2}" fill-opacity="0.25" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
		<circle cx="24" cy="12.5" r="2.0" fill="{C2}" stroke="{C1}" stroke-width="1.6"/>
		<path d="M 13.5 21 C 12 29 15.5 35.5 24 35.5 C 32.5 35.5 36 29 34.5 21 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
		<path d="M 13.5 22.5 C 10 22 10 27 13.5 27 M 34.5 22.5 C 38 22 38 27 34.5 27" fill="none" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M 17.5 35 L 15.5 41.5 M 24 35.5 L 24 42 M 30.5 35 L 32.5 41.5" fill="none" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<circle cx="24" cy="27.5" r="3.2" fill="{C2}" fill-opacity="0.5" stroke="{C2}" stroke-width="1.5"/>
		<path d="M 35 12 C 37.5 9.5 34.5 7 37 4.5" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	"skill_forging": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
		<path d="M 9 27 L 17 24 L 36 24 L 39 27.5 L 33 30.5 L 35 38 L 15 38 L 17 30.5 L 11 29 Z" fill="{C1}" fill-opacity="0.2" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
		<path d="M 12 40.5 L 38 40.5" fill="none" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<rect x="19" y="10" width="11" height="6.5" rx="1.5" transform="rotate(-24 24.5 13.2)" fill="{C1}" fill-opacity="0.28" stroke="{C1}" stroke-width="2.1"/>
		<path d="M 27.5 15 L 37.5 21.5" fill="none" stroke="{C1}" stroke-width="2.5" stroke-linecap="round"/>
		<path d="M 15 16 L 15 21 M 12.5 18.5 L 17.5 18.5" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<circle cx="21.5" cy="20" r="1.4" fill="{C2}"/>
	</svg>""",

	"skill_talisman": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
		<rect x="10" y="11" width="18" height="27" rx="2" fill="{C1}" fill-opacity="0.12" stroke="{C1}" stroke-width="2.1"/>
		<path d="M 14 16 L 24 16 M 21 20 C 15 20.5 15 24.5 19 25 C 23 25.5 23 29.5 16 30.5 M 15 34 L 23 34" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M 28.5 25.5 L 39.5 9.5" fill="none" stroke="{C1}" stroke-width="2.7" stroke-linecap="round"/>
		<path d="M 28.5 25.5 Q 24.5 28.5 24 33.5 Q 28.5 32 30.5 27.5 Z" fill="{C2}" fill-opacity="0.7" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round"/>
	</svg>""",

	"skill_cultivation": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
		<circle cx="24" cy="24" r="14.5" fill="{C1}" fill-opacity="0.08" stroke="{C1}" stroke-width="2.1" stroke-dasharray="18 5"/>
		<path d="M 24 9.5 A 7.25 7.25 0 0 1 24 24 A 7.25 7.25 0 0 0 24 38.5" fill="none" stroke="{C2}" stroke-width="2.1" stroke-linecap="round"/>
		<circle cx="24" cy="16.8" r="2.0" fill="{C2}"/>
		<circle cx="24" cy="31.2" r="2.0" fill="none" stroke="{C1}" stroke-width="1.8"/>
		<path d="M 14 41.5 Q 24 38.5 34 41.5" fill="none" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	"skill_combat": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 7 L28 14 L27 31 L21 31 L20 14 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M24 11 L24 29" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M16 31 Q24 34 32 31" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M24 32 L24 40" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M12 19 C9 25 11 31 15 35 M36 19 C39 25 37 31 33 35" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	# ==================== 3. 灵草、木矿与掉落材料 (11) ====================
	"item_qingye": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 41 L24 17" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 33 C14 32 9 24 11 16 C18 16 23 22 24 29" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.18"/>
		<path d="M24 29 C34 28 39 20 37 12 C30 12 25 18 24 25" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.18"/>
		<path d="M23 30 Q17 24 14 19 M25 26 Q31 20 34 15" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<circle cx="24" cy="10" r="2.4" fill="{C2}"/>
	</svg>""",

	"item_ninglu": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 41 L24 26" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 26 C16 24 12 18 14 11 C19 12 22 16 24 21 C26 16 29 12 34 11 C36 18 32 24 24 26 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M24 23 C20 18 21 11 24 8 C27 11 28 18 24 23 Z" stroke="{C2}" stroke-width="2.0" fill="{C2}" fill-opacity="0.28"/>
		<path d="M35 25 C35 28 38 30 35 33 C32 30 35 28 35 25 Z" fill="{C2}"/>
		<path d="M24 35 Q18 33 15 36 M24 35 Q30 33 33 36" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	"item_ziyun": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M23 41 C23 35 22 30 24 25" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M10 23 C8 15 15 10 24 11 C33 10 40 15 38 23 C36 27 30 26 24 25 C18 26 12 27 10 23 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.2"/>
		<path d="M15 21 C16 17 20 15 24 15 C28 15 32 17 33 21" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M24 34 C29 31 35 31 36 35 C34 38 29 38 24 36" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.14"/>
	</svg>""",

	"item_chiyan": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 41 L24 28" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 30 C16 28 13 21 16 14 C19 18 21 16 24 8 C27 16 29 18 32 14 C35 21 32 28 24 30 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.22"/>
		<path d="M24 28 C21 25 21 20 24 16 C27 20 27 25 24 28 Z" fill="{C2}"/>
		<path d="M15 35 Q24 32 33 35" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"item_wood": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<ellipse cx="15" cy="31" rx="6" ry="8" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.18"/>
		<ellipse cx="15" cy="31" rx="2.5" ry="3.5" stroke="{C2}" stroke-width="1.8"/>
		<path d="M15 23 L33 13 C37 13 40 17 39 22 C38 26 36 28 33 29 L15 39" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.12"/>
		<path d="M23 23 L31 19 M26 28 L34 24" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M27 16 C28 11 32 9 35 10 C34 13 31 15 27 16 Z" stroke="{C2}" stroke-width="1.8" fill="{C2}" fill-opacity="0.25"/>
	</svg>""",

	"item_ore": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<polygon points="10,36 14,22 22,20 27,36" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<polygon points="21,36 25,11 33,14 36,36" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.22"/>
		<polygon points="31,36 36,23 41,26 39,36" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.14"/>
		<path d="M29 14 L27 34 M18 22 L17 34" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M8 36 L42 36" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"item_seed": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 9 C32 17 35 24 35 30 C35 36.5 30 40 24 40 C18 40 13 36.5 13 30 C13 24 16 17 24 9 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.18"/>
		<path d="M24 34 C20 31 20 24 25 20 C27 23 27 28 24 34 Z" stroke="{C2}" stroke-width="2.0" fill="{C2}" fill-opacity="0.3"/>
		<circle cx="33" cy="13" r="1.8" fill="{C2}"/>
	</svg>""",

	"item_spirit_berry": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 15 C32 15 37 21 36 29 C35 36 29 40 24 40 C19 40 13 36 12 29 C11 21 16 15 24 15 Z" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.22"/>
		<path d="M24 15 C24 11 26 9 28 8" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 14 C19 10 14 11 13 15 C17 16 21 16 24 14 Z" stroke="{C2}" stroke-width="2.0" fill="{C2}" fill-opacity="0.25"/>
		<path d="M18 24 C18 21 20 19 23 19" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	"item_beast_core": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="12" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.2"/>
		<path d="M10 28 C12 33 23 34 32 29 C39 25 41 19 36 16" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M20 18 L26 22 L22 26 L28 30" stroke="{C2}" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	"item_demon_essence": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 7 C31 14 36 21 35 29 C34 36 29 40 24 40 C19 40 14 36 13 29 C12 22 16 16 20 13 C20 17 22 18 24 7 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.18"/>
		<polygon points="24,20 29,27 24,34 19,27" stroke="{C2}" stroke-width="2.0" fill="{C2}" fill-opacity="0.35"/>
	</svg>""",

	"item_spirit_stone": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<polygon points="24,7 36,16 36,32 24,41 12,32 12,16" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.18"/>
		<polygon points="24,14 30,19 30,29 24,34 18,29 18,19" stroke="{C2}" stroke-width="1.8" stroke-linejoin="round" fill="{C2}" fill-opacity="0.22"/>
		<path d="M24 7 L24 14 M36 16 L30 19 M36 32 L30 29 M24 41 L24 34 M12 32 L18 29 M12 16 L18 19" stroke="{C1}" stroke-width="1.4"/>
	</svg>""",

	# ==================== 4. 丹药与符箓消耗品 (5) ====================
	"item_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="25" r="12" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.2"/>
		<path d="M17 22 C19 18 24 17 28 19" stroke="{C2}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M20 29 C24 31 29 29 31 25" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M12 12 L14 14 M36 12 L34 14 M24 8 L24 10" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	"item_heal_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M21 9 L27 9 M22 9 L22 13 C18 14 17 19 20 22 C14 25 13 33 18 38 C21 40 27 40 30 38 C35 33 34 25 28 22 C31 19 30 14 26 13 L26 9" stroke="{C1}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M19 22 L29 22" stroke="{C2}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M24 27 L24 34 M20.5 30.5 L27.5 30.5" stroke="{C2}" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"item_breakthrough_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="10" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.26"/>
		<circle cx="24" cy="24" r="16" stroke="{C2}" stroke-width="1.6" stroke-dasharray="4 4"/>
		<path d="M19 22 Q24 17 29 22 M19 26 Q24 31 29 26" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M24 4 L24 8 M24 40 L24 44 M4 24 L8 24 M40 24 L44 24" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	"item_shield_talisman": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="14" y="7" width="20" height="34" rx="2" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.14"/>
		<path d="M18 12 L30 12 M18 36 L30 36" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
		<polygon points="24,16 30,20 30,28 24,32 18,28 18,20" stroke="{C2}" stroke-width="2.0" fill="{C2}" fill-opacity="0.24"/>
		<circle cx="24" cy="24" r="2" fill="{C1}"/>
	</svg>""",

	"item_thunder_talisman": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="14" y="7" width="20" height="34" rx="2" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.14"/>
		<path d="M18 12 L30 12 M18 36 L30 36" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M26 15 L19 24 L25 24 L21 33 L29 22 L24 22 Z" stroke="{C2}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.35"/>
	</svg>""",

	"item_fireball_talisman": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="14" y="7" width="20" height="34" rx="2" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.14"/>
		<path d="M18 12 L30 12 M18 36 L30 36" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M24 15 C27 19 29 22 29 26 C29 29.5 26.8 32 24 32 C21.2 32 19 29.5 19 26 C19 23.5 20.5 21.5 22 20 C21.8 22 22.8 23 23.5 23 C23 20.2 23.2 17.5 24 15 Z" stroke="{C2}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.28"/>
		<circle cx="24" cy="27.5" r="1.8" fill="{C1}"/>
	</svg>""",

	"item_qingmu_ward": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="14" y="7" width="20" height="34" rx="2" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.14"/>
		<path d="M18 12 L30 12 M18 36 L30 36" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M24 31 L24 18" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M24 27 C19.5 26.5 18 22.5 20 19.5 C22.5 20 24 22.5 24 25" stroke="{C2}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
		<path d="M24 24 C28.5 23.5 30 19.5 28 16.5 C25.5 17 24 19.5 24 22" stroke="{C2}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
	</svg>""",

	"item_jianmu_ward": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="13" y="6" width="22" height="36" rx="2.5" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.14"/>
		<path d="M17 11 L31 11 M17 37 L31 37" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M24 33 L24 16 M24 28 L19 24 M24 26 L29 22 M24 21 L20 18 M24 20 L28 17" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
		<circle cx="24" cy="16" r="3" stroke="{C2}" stroke-width="2.0" fill="{C2}" fill-opacity="0.28"/>
		<circle cx="19" cy="24" r="1.6" fill="{C2}"/>
		<circle cx="29" cy="22" r="1.6" fill="{C2}"/>
	</svg>""",

	"item_xingchen_thunder": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="13" y="6" width="22" height="36" rx="2.5" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.15"/>
		<path d="M17 11 L31 11 M17 37 L31 37" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
		<polygon points="24,14 25.6,18.4 30,20 25.6,21.6 24,26 22.4,21.6 18,20 22.4,18.4" stroke="{C2}" stroke-width="1.8" stroke-linejoin="round" fill="{C2}" fill-opacity="0.28"/>
		<path d="M25.5 22 L21 28 L25 28 L22.5 34" stroke="{C1}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	"item_hundun_thunder": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="13" y="6" width="22" height="36" rx="2.5" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.16"/>
		<path d="M17 11 L31 11 M17 37 L31 37" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
		<circle cx="24" cy="24" r="7" stroke="{C2}" stroke-width="1.8" stroke-dasharray="4 3" fill="{C2}" fill-opacity="0.18"/>
		<path d="M26 15 L20.5 24 L25.5 24 L21 33" stroke="{C1}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M18 17 L20 19 M30 31 L28 29" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"item_worldtree_ward": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="13" y="6" width="22" height="36" rx="2.5" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.16"/>
		<rect x="16" y="9" width="16" height="30" rx="1.2" stroke="{C2}" stroke-width="1.4" stroke-opacity="0.65"/>
		<circle cx="24" cy="21" r="6" stroke="{C2}" stroke-width="2.0" fill="{C2}" fill-opacity="0.26"/>
		<path d="M24 34 L24 19 M24 27 L20 24 M24 25 L28 22 M20 34 C22 32 26 32 28 34" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	# ==================== 炼气中阶材料 / 过渡装备 / 高阶回血丹 ====================
	"item_cuiyun_wood": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="9" y="18" width="24" height="14" rx="4" transform="rotate(-18 21 25)" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.16"/>
		<ellipse cx="32" cy="21.5" rx="3.5" ry="6.5" transform="rotate(-18 32 21.5)" stroke="{C1}" stroke-width="2.0" fill="{C2}" fill-opacity="0.28"/>
		<path d="M16 26 C20 24 23 23.5 27 22" stroke="{C1}" stroke-width="1.5" stroke-linecap="round"/>
		<path d="M26 15 C28 10 33 9 36 11 C34 15 30 16 26 15 Z" stroke="{C2}" stroke-width="1.8" stroke-linejoin="round" fill="{C2}" fill-opacity="0.28"/>
	</svg>""",

	"item_qinggang_ore": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<polygon points="14,35 10,22 20,11 33,13 38,25 31,36" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<polyline points="20,11 23,23 14,35" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round"/>
		<polyline points="23,23 38,25" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
		<polygon points="20,11 33,13 23,23" fill="{C2}" fill-opacity="0.26"/>
		<path d="M14 14 L16 16 M35 10 L33 12" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	"equip_qinggang_sword": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M36 10 L17 29 L19 31 L38 12 L38 10 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
		<path d="M21 27 L34 14" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M13 25 L23 35" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M16 32 L10 38" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<circle cx="9.5" cy="38.5" r="2.0" fill="{C2}" stroke="{C1}" stroke-width="1.4"/>
	</svg>""",

	"equip_cuiyun_robe": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M18 10 L10 17 L13 24 L17 21 L15 39 L33 39 L31 21 L35 24 L38 17 L30 10 L24 15 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M18 10 L27 21 M30 10 L24 15" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M16.5 26 L31.5 26" stroke="{C2}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M24 26 L22 33 M24 26 L26 33" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	"item_taiyi_heal": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="21" r="9.5" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.22"/>
		<path d="M19 18 C21 15.5 25 15 28 17" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M11 31 C15 28 20 29 24 34 C28 29 33 28 37 31 C33 36 28 38 24 38 C20 38 15 36 11 31 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.26"/>
		<path d="M24 8 L24 10 M13 13 L15 15 M35 13 L33 15" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"item_hundun_heal": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="15" stroke="{C2}" stroke-width="1.8" stroke-dasharray="5 3.5" fill="none"/>
		<circle cx="24" cy="24" r="10" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.24"/>
		<path d="M19 21 C21 18 26 18 28.5 21" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M20 27 C23 29 27 28 29 25" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	"item_hongmeng_heal": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="15.5" stroke="{C2}" stroke-width="1.5" stroke-opacity="0.7" fill="none"/>
		<circle cx="24" cy="24" r="10.5" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.26"/>
		<polygon points="24,17 25.8,22.2 31,24 25.8,25.8 24,31 22.2,25.8 17,24 22.2,22.2" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round" fill="{C2}" fill-opacity="0.32"/>
		<path d="M24 5 L24 7.5 M24 40.5 L24 43 M5 24 L7.5 24 M40.5 24 L43 24" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	# ==================== 5. 装备与仙坊阁法器宝具 (11) ====================
	"equip_sword": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M 17.2 26.2 L 34.4 10.6 L 41 7 L 19.5 28.5 Z" fill="{C1}" fill-opacity="0.12"/>
		<path d="M 19.5 28.5 L 41 7 L 37.4 13.6 L 21.8 30.8 Z" fill="{C1}" fill-opacity="0.28"/>
		<path d="M 17.2 26.2 L 34.4 10.6 L 41 7 L 37.4 13.6 L 21.8 30.8 Z" fill="none" stroke="{C1}" stroke-width="2.3" stroke-linejoin="round"/>
		<path d="M 20.2 27.8 L 39 9" fill="none" stroke="{C1}" stroke-width="1.5" stroke-linecap="round" stroke-opacity="0.7"/>
		<path d="M 24.5 23.5 L 36.2 11.8" fill="none" stroke="{C2}" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.85"/>
		<path d="M 11.4 36.6 L 16.4 31.6" fill="none" stroke="{C1}" stroke-width="3.2" stroke-linecap="round"/>
		<circle cx="9.5" cy="38.5" r="2.6" fill="{C2}" fill-opacity="0.4" stroke="{C1}" stroke-width="2.1"/>
		<path d="M 12.2 24.2 Q 15.5 26.8 20.5 27.5 Q 21.2 32.5 23.8 35.8 L 21.6 36.6 Q 17.8 34.2 15.8 32.2 Q 13.8 30.2 11.4 26.4 Z" fill="{C2}" fill-opacity="0.45" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
		<path d="M 11.5 18 Q 18.5 10.5 30 8.2" fill="none" stroke="{C2}" stroke-width="1.9" stroke-linecap="round" stroke-opacity="0.88"/>
		<circle cx="32.8" cy="7.6" r="1.2" fill="{C2}" fill-opacity="0.85"/>
		<path d="M 26 39.5 Q 35.5 32.5 39 19.5" fill="none" stroke="{C2}" stroke-width="1.9" stroke-linecap="round" stroke-opacity="0.82"/>
		<path d="M 27.5 32.2 L 34.8 24.8" fill="none" stroke="{C2}" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.65"/>
	</svg>""",

	"equip_robe": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M18 9 L24 14 L30 9 L39 16 L36 25 L32 23 L34 39 L14 39 L16 23 L12 25 L9 16 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M19 10 L27 24 M29 10 L23 19" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M16 26 L32 26" stroke="{C2}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M24 26 L24 34" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	"tool_hoe": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M11 38 L34 15" stroke="{C1}" stroke-width="2.6" stroke-linecap="round"/>
		<path d="M27 10 L38 21 L33 25 L26 17 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
		<path d="M18 20 C14 19 12 15 14 12 C17 12 19 15 18 20 Z" stroke="{C2}" stroke-width="1.8" fill="{C2}" fill-opacity="0.25"/>
	</svg>""",

	"tool_axe": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M12 39 L35 12" stroke="{C1}" stroke-width="2.6" stroke-linecap="round"/>
		<path d="M25 10 C34 10 40 16 40 25 C34 26 28 23 24 18 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
		<path d="M35 14 C37 17 37 21 36 23" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
	</svg>""",

	"tool_pick": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M11 38 L33 16" stroke="{C1}" stroke-width="2.6" stroke-linecap="round"/>
		<path d="M16 10 Q32 10 39 27 L34 29 Q28 17 17 15 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
		<circle cx="35" cy="13" r="2.2" fill="{C2}"/>
	</svg>""",

	"gear_furnace": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<polygon points="15,19 33,19 37,27 32,36 16,36 11,27" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.18"/>
		<path d="M16 19 L20 13 L28 13 L32 19 M24 13 L24 9" stroke="{C1}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M17 36 L14 41 M31 36 L34 41" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 23 C28 26 28 31 24 32 C20 31 20 26 24 23 Z" fill="{C2}"/>
	</svg>""",

	"gear_hammer": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M12 38 L27 23" stroke="{C1}" stroke-width="2.8" stroke-linecap="round"/>
		<polygon points="19,14 28,8 40,20 31,26" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
		<path d="M27 14 L33 20" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M36 9 L40 9 M39 12 L42 14" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"gear_mat": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<ellipse cx="24" cy="30" rx="16" ry="7" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.18"/>
		<path d="M8 30 L8 35 C8 39 15 41 24 41 C33 41 40 39 40 35 L40 30" stroke="{C1}" stroke-width="2.2"/>
		<ellipse cx="24" cy="30" rx="8" ry="3.2" stroke="{C2}" stroke-width="1.8"/>
		<path d="M16 18 Q20 13 18 9 M24 17 Q28 12 26 7 M32 18 Q36 13 34 9" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"gear_bell": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="11" r="3" stroke="{C2}" stroke-width="2.0"/>
		<path d="M24 14 C16 14 14 21 13 28 L10 34 L38 34 L35 28 C34 21 32 14 24 14 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.18"/>
		<circle cx="24" cy="37" r="2.6" fill="{C2}"/>
		<path d="M8 22 C6 25 6 28 8 31 M40 22 C42 25 42 28 40 31" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"gear_brush": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M38 10 L19 29" stroke="{C1}" stroke-width="3.0" stroke-linecap="round"/>
		<path d="M19 29 C14 30 10 34 9 39 C14 38 18 35 20 30 Z" stroke="{C2}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.35"/>
		<path d="M29 19 L33 23" stroke="{C2}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M12 16 Q18 11 24 16" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"gear_array": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="16" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.12"/>
		<polygon points="24,10 36,31 12,31" stroke="{C2}" stroke-width="1.8" stroke-linejoin="round"/>
		<polygon points="24,38 36,17 12,17" stroke="{C2}" stroke-width="1.8" stroke-linejoin="round"/>
		<circle cx="24" cy="24" r="3.5" fill="{C2}"/>
	</svg>""",

	# ==================== 6. 秘境妖兽与头目 (6) ====================
	"enemy_wild_wolf": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M12 19 L9 6 L20 13 L24 11 L28 13 L39 6 L36 19 L39 25 L34 29 L29 38 L24 41 L19 38 L14 29 L9 25 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.14"/>
		<path d="M15 21 L21 24 L16 25 Z" fill="{C2}" stroke="{C2}" stroke-width="1.2" stroke-linejoin="round"/>
		<path d="M33 21 L27 24 L32 25 Z" fill="{C2}" stroke="{C2}" stroke-width="1.2" stroke-linejoin="round"/>
		<path d="M24 14 L22 18 L24 20 L26 18 Z" fill="{C2}"/>
		<path d="M21 33 L24 36 L27 33 Z" fill="{C1}"/>
		<path d="M19 29 L24 31 L29 29" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"enemy_iron_boar": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M11 22 L14 13 L24 10 L34 13 L37 22 L35 33 L28 38 L20 38 L13 33 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.14"/>
		<path d="M14 13 L9 10 L11 18 M34 13 L39 10 L37 18" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
		<path d="M15 34 C9 32 7 26 9 20 C11 25 13 28 17 30" stroke="{C2}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" fill="{C2}" fill-opacity="0.25"/>
		<path d="M33 34 C39 32 41 26 39 20 C37 25 35 28 31 30" stroke="{C2}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" fill="{C2}" fill-opacity="0.25"/>
		<path d="M16 21 L21 23 M32 21 L27 23" stroke="{C2}" stroke-width="2.2" stroke-linecap="round"/>
		<ellipse cx="24" cy="31" rx="5" ry="3.5" stroke="{C1}" stroke-width="2.0"/>
		<circle cx="22.3" cy="31" r="1" fill="{C1}"/>
		<circle cx="25.7" cy="31" r="1" fill="{C1}"/>
	</svg>""",

	"enemy_wolf_king": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M12 22 L8 8 L19 16 L24 14 L29 16 L40 8 L36 22 L41 27 L35 32 L30 40 L24 43 L18 40 L13 32 L7 27 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M20 7 C22 11 26 11 28 7 C27 12 21 12 20 7 Z" stroke="{C2}" stroke-width="2.0" fill="{C2}"/>
		<path d="M14 23 L21 26 L15 27 Z" fill="{C2}"/>
		<path d="M34 23 L27 26 L33 27 Z" fill="{C2}"/>
		<path d="M21 35 L24 38 L27 35 Z" fill="{C1}"/>
		<path d="M17 31 L21 33 L24 31 L27 33 L31 31" stroke="{C2}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	"enemy_miasma_python": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 9 36.5 C 9 30.5 39 30.5 39 36.5 C 39 42 11 42 11 36.5 Z" fill="{C1}" fill-opacity="0.20" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 14 31.2 C 14 26 34.5 26 34.5 31.2 C 34.5 34.5 14 34.5 14 31.2 Z" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.0"/>
	  <path d="M 27.5 27 C 31.5 22 30.5 15.5 25 12.2 L 15.5 10.8 L 11.5 15.8 L 18.8 19.6 C 22.8 20.8 23.2 24.5 21.5 27.5 Z" fill="{C1}" fill-opacity="0.24" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <circle cx="19.2" cy="14.4" r="1.7" fill="{C2}"/>
	  <path d="M 14.2 17 L 13.5 20.5 M 17.2 18.6 L 16.8 21.4" fill="none" stroke="{C1}" stroke-width="1.5" stroke-linecap="round"/>
	  <path d="M 11.5 15.8 L 7 17.5 M 8.8 16.8 L 6.5 15.2 M 8.8 16.8 L 7.2 19.8" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	  <circle cx="37.5" cy="13.5" r="2.2" fill="{C2}" fill-opacity="0.35" stroke="{C2}" stroke-width="1.4"/>
	  <circle cx="40" cy="20.5" r="1.4" fill="{C2}" fill-opacity="0.75"/>
	  <circle cx="9.5" cy="25" r="1.6" fill="{C2}" fill-opacity="0.65"/>
	</svg>""",

	"enemy_stone_golem": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 8 41 L 10 24.5 L 17.5 20 L 30.5 20 L 38 24.5 L 40 41 Z" fill="{C1}" fill-opacity="0.20" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 10 24.5 L 16 28 L 15 41 M 38 24.5 L 32 28 L 33 41" fill="none" stroke="{C1}" stroke-width="1.7" stroke-linejoin="round"/>
	  <polygon points="17.5,19.5 16.5,10 24,7.5 31.5,10 30.5,19.5" fill="{C1}" fill-opacity="0.26" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 20 13.8 L 28 13.8" fill="none" stroke="{C2}" stroke-width="2.4" stroke-linecap="round"/>
	  <polygon points="24,25.5 28,29.5 24,33.5 20,29.5" fill="{C2}" fill-opacity="0.72" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round"/>
	  <path d="M 11.5 32 L 15 33.5 M 33 34 L 36.8 31.5 M 24 33.5 L 24 38.5" fill="none" stroke="{C1}" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.65"/>
	</svg>""",

	"enemy_ruin_guardian": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="21" r="18.2" fill="none" stroke="{C2}" stroke-width="1.5" stroke-opacity="0.55" stroke-dasharray="8 4"/>
	  <path d="M 24 1.8 L 24 5.2 M 37.6 7.4 L 35.2 9.8 M 43.2 21 L 39.8 21 M 10.4 7.4 L 12.8 9.8 M 4.8 21 L 8.2 21" fill="none" stroke="{C2}" stroke-width="1.9" stroke-linecap="round"/>
	  <path d="M 14.5 21 L 4.5 22.5 L 6.8 34.5 L 14.5 32 Z M 33.5 21 L 43.5 22.5 L 41.2 34.5 L 33.5 32 Z" fill="{C1}" fill-opacity="0.24" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 13.5 21.5 L 34.5 21.5 L 33 43 L 15 43 Z" fill="{C1}" fill-opacity="0.20" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <polygon points="17.5,20.5 16,10.5 20.2,12.5 24,6 27.8,12.5 32,10.5 30.5,20.5" fill="{C1}" fill-opacity="0.28" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 19.2 15.2 L 22.4 16 M 28.8 15.2 L 25.6 16" fill="none" stroke="{C2}" stroke-width="2.2" stroke-linecap="round"/>
	  <polygon points="24,24.8 29.2,30 24,35.2 18.8,30" fill="{C2}" fill-opacity="0.85" stroke="{C1}" stroke-width="1.7" stroke-linejoin="round"/>
	  <circle cx="24" cy="30" r="2.1" fill="#FFFFFF" fill-opacity="0.65"/>
	  <path d="M 14.5 27.5 L 18.5 30 M 33.5 27.5 L 29.5 30 M 18 39 L 24 37.2 L 30 39" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	# ==================== 6b. 星陨古墟三阶妖兽 (3) ====================
	"enemy_star_wraith": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 24 7.5 C 15.5 7.5 12 15 13 24 C 12 31.5 9.5 37 13.5 41.5 L 18.5 37 L 23.5 42 L 28.5 37 L 34 41.5 C 37.5 36.5 35.5 30 35 24 C 36 15 32.5 7.5 24 7.5 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 24 11.5 C 19.2 11.5 17.2 15.8 18.2 21 C 21 23 27 23 29.8 21 C 30.8 15.8 28.8 11.5 24 11.5 Z" fill="{C1}" fill-opacity="0.32" stroke="{C1}" stroke-width="1.7"/>
	  <circle cx="21.4" cy="16.8" r="1.6" fill="{C2}"/>
	  <circle cx="26.6" cy="16.8" r="1.6" fill="{C2}"/>
	  <path d="M 19 28 Q 24 30.5 29 28" fill="none" stroke="{C2}" stroke-width="1.5" stroke-linecap="round" stroke-opacity="0.7"/>
	  <path d="M 9.5 11.5 L 10.4 14.1 L 13 15 L 10.4 15.9 L 9.5 18.5 L 8.6 15.9 L 6 15 L 8.6 14.1 Z" fill="{C2}" fill-opacity="0.88"/>
	  <circle cx="39" cy="18" r="1.6" fill="{C2}" fill-opacity="0.8"/>
	  <circle cx="38" cy="30" r="1.2" fill="{C2}" fill-opacity="0.55"/>
	</svg>""",

	"enemy_frost_ape": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 7.5 40 L 9 25 L 13 19 L 15 11.5 L 21 15 L 24 9.5 L 27 15 L 33 11.5 L 35 19 L 39 25 L 40.5 40 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <polygon points="10,23 6,14.5 13,17" fill="{C2}" fill-opacity="0.36" stroke="{C2}" stroke-width="1.6" stroke-linejoin="round"/>
	  <polygon points="38,23 42,14.5 35,17" fill="{C2}" fill-opacity="0.36" stroke="{C2}" stroke-width="1.6" stroke-linejoin="round"/>
	  <path d="M 16 18.5 C 16 13.5 32 13.5 32 18.5 C 33 25 29.8 31.5 24 32.5 C 18.2 31.5 15 25 16 18.5 Z" fill="{C1}" fill-opacity="0.24" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 18 19.2 L 24 21.5 L 30 19.2" fill="none" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
	  <circle cx="20.5" cy="21.8" r="1.5" fill="{C2}"/>
	  <circle cx="27.5" cy="21.8" r="1.5" fill="{C2}"/>
	  <path d="M 18.8 28.5 L 20.4 25 L 22 28.5 L 26 28.5 L 27.6 25 L 29.2 28.5" fill="none" stroke="{C1}" stroke-width="1.7" stroke-linejoin="round"/>
	  <path d="M 14 35.5 L 18 32.5 M 34 35.5 L 30 32.5" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	"enemy_star_dragon": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <ellipse cx="24" cy="24" rx="20.5" ry="8.5" transform="rotate(-24 24 24)" fill="none" stroke="{C2}" stroke-width="1.6" stroke-opacity="0.72"/>
	  <path d="M 18.5 14.5 Q 10.5 10.5 8 4.2 M 14.2 10.8 L 15.8 5.2 M 29.5 14.5 Q 37.5 10.5 40 4.2 M 33.8 10.8 L 32.2 5.2" fill="none" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
	  <path d="M 14.5 43.5 Q 12.8 33 17 25.5 L 12.2 20.5 L 17.5 13.5 L 24 11.5 L 30.5 13.5 L 35.8 20.5 L 31 25.5 Q 35.2 33 33.5 43.5 Z" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 17.5 18.5 L 22 20.5 M 30.5 18.5 L 26 20.5" fill="none" stroke="{C2}" stroke-width="2.1" stroke-linecap="round"/>
	  <path d="M 14.5 23.5 Q 8 25.5 5 29.5 M 33.5 23.5 Q 40 25.5 43 29.5" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	  <circle cx="24" cy="33.5" r="4.8" fill="{C2}" fill-opacity="0.32" stroke="{C2}" stroke-width="1.9"/>
	  <path d="M 24 29.5 L 25.1 32.4 L 28 33.5 L 25.1 34.6 L 24 37.5 L 22.9 34.6 L 20 33.5 L 22.9 32.4 Z" fill="{C2}"/>
	  <polygon points="7,35 10.5,33.5 11.5,37 8,38.5" fill="{C1}" fill-opacity="0.32" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round"/>
	  <polygon points="39.5,14 42.5,12.5 43,16 40,17" fill="{C2}" fill-opacity="0.7"/>
	</svg>""",

	# ==================== 7. 洞府灵田：空闲 / 未开垦 / 生长阶段 ====================
	## 空闲：等距立体灵畦 + 「田」字阡陌 + 星芒（可播种）
	"farm_empty": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<polygon points="24,14 42,24.5 24,35 6,24.5" fill="{C1}" fill-opacity="0.10"/>
		<polygon points="6,24.5 24,35 24,40.5 6,30" fill="{C1}" fill-opacity="0.22"/>
		<polygon points="24,35 42,24.5 42,30 24,40.5" fill="{C1}" fill-opacity="0.34"/>
		<path d="M 24 14 L 42 24.5 L 42 30 L 24 40.5 L 6 30 L 6 24.5 Z" fill="none" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
		<path d="M 6 24.5 L 24 35 L 42 24.5 M 24 35 L 24 40.5" fill="none" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
		<polygon points="24,16.5 37.7,24.5 24,32.5 10.3,24.5" fill="{C2}" fill-opacity="0.18"/>
		<path d="M 17.1 20.5 L 30.9 28.5 M 30.9 20.5 L 17.1 28.5" fill="none" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M 22.4 19.5 L 25.6 21.4 M 29.2 23.6 L 32.4 25.5 M 22.4 27.6 L 25.6 29.5 M 15.6 23.6 L 18.8 25.5" fill="none" stroke="{C1}" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.58"/>
		<path d="M 36.5 6.5 Q 37.1 9.9 40.5 10.5 Q 37.1 11.1 36.5 14.5 Q 35.9 11.1 32.5 10.5 Q 35.9 9.9 36.5 6.5 Z" fill="{C2}" fill-opacity="0.9"/>
		<circle cx="12.5" cy="11.5" r="1.8" fill="{C2}" fill-opacity="0.78"/>
		<circle cx="22.5" cy="8.2" r="1.2" fill="{C2}" fill-opacity="0.6"/>
	</svg>""",

	## 未开垦：荒石 + 杂草 + 灰淡轮廓（与空闲灵畦明确区分）
	"farm_locked": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<polygon points="24,16 42,26.5 24,37 6,26.5" fill="{C1}" fill-opacity="0.08"/>
		<polygon points="6,26.5 24,37 24,42 6,31.5" fill="{C1}" fill-opacity="0.18"/>
		<polygon points="24,37 42,26.5 42,31.5 24,42" fill="{C1}" fill-opacity="0.28"/>
		<path d="M 24 16 L 42 26.5 L 42 31.5 L 24 42 L 6 31.5 L 6 26.5 Z" fill="none" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" stroke-opacity="0.82"/>
		<path d="M 6 26.5 L 24 37 L 42 26.5 M 24 37 L 24 42" fill="none" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" stroke-opacity="0.78"/>
		<path d="M 14.5 27.5 L 16.5 21 L 22.5 19.5 L 26.5 23 L 25.5 28.5 L 18.5 30 Z" fill="{C1}" fill-opacity="0.24" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
		<path d="M 22.5 19.5 L 21.5 24.5 L 26.5 23" fill="none" stroke="{C1}" stroke-width="1.3" stroke-linecap="round" stroke-opacity="0.55"/>
		<path d="M 28.5 28.5 L 30.5 25.5 L 34.5 26 L 35 29.5 L 30.5 30.5 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round"/>
		<path d="M 27.5 22.5 Q 27 17.5 29.5 15 M 27.5 22.5 Q 29.5 19 32.5 18 M 14 23.5 Q 12.5 20.5 10.5 19.5" fill="none" stroke="{C2}" stroke-width="1.7" stroke-linecap="round" stroke-opacity="0.65"/>
	</svg>""",

	"farm_stage1": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M10 37 Q24 31 38 37" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 34 L24 23" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 26 C18 26 15 21 17 17 C21 17 24 20 24 25" stroke="{C2}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.25"/>
		<path d="M24 24 C30 24 33 19 31 15 C27 15 24 18 24 23" stroke="{C2}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.25"/>
	</svg>""",

	"farm_stage2": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M9 39 Q24 33 39 39" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 36 C24 28 24 21 24 14" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 31 C15 30 11 24 13 18 C19 18 23 23 24 29" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.2"/>
		<path d="M24 28 C33 27 37 21 35 15 C29 15 25 20 24 26" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.2"/>
		<path d="M24 15 C21 12 22 9 24 8 C26 9 27 12 24 15 Z" stroke="{C2}" stroke-width="2.0" fill="{C2}" fill-opacity="0.35"/>
	</svg>""",

	"farm_stage3": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M9 40 Q24 34 39 40" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 37 L24 20" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 33 C14 32 10 26 12 20 C18 20 23 25 24 31" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.22"/>
		<path d="M24 31 C34 30 38 24 36 18 C30 18 25 23 24 29" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.22"/>
		<path d="M24 22 C17 20 15 14 18 9 C21 11 23 14 24 18 C25 14 27 11 30 9 C33 14 31 20 24 22 Z" stroke="{C2}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.35"/>
		<circle cx="24" cy="14" r="2.2" fill="{C1}"/>
		<circle cx="11" cy="13" r="1.8" fill="{C2}"/>
		<circle cx="37" cy="12" r="1.8" fill="{C2}"/>
		<circle cx="24" cy="6" r="1.6" fill="{C2}"/>
	</svg>""",

	"farm_stage_sprout": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M9 39 Q24 33 39 39" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 37 L24 27" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 31 C18 31 14 27 15 21 C21 21 24 25 24 30 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.28"/>
		<path d="M24 29 C30 29 34 25 33 19 C27 19 24 23 24 28 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.28"/>
		<circle cx="24" cy="24" r="1.5" fill="{C2}"/>
	</svg>""",

	"farm_stage_growing": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M9 40 Q24 34 39 40" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 38 C24 31 24 24 24 16" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 33 C15 32 11 26 13 20 C19 20 23 25 24 31 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.22"/>
		<path d="M24 29 C33 28 37 22 35 16 C29 16 25 21 24 27 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.22"/>
		<path d="M24 22 C20 19 20 14 23 11 C26 13 27 18 24 22 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.35"/>
		<circle cx="24" cy="9" r="1.8" fill="{C2}"/>
	</svg>""",

	"farm_stage_mature": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M9 40 Q24 34 39 40" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 38 L24 19" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 34 C14 33 10 26 12 20 C18 20 23 25 24 31 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
		<path d="M24 31 C34 30 38 23 36 17 C30 17 25 22 24 29 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
		<path d="M24 21 C18 19 16 13 19 8 C22 10 24 13 24 17 C25 13 27 10 30 8 C33 13 30 19 24 21 Z" stroke="{C2}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.38"/>
		<circle cx="24" cy="14" r="2.2" fill="{C1}"/>
		<circle cx="11" cy="12" r="1.8" fill="{C2}"/>
		<circle cx="37" cy="11" r="1.8" fill="{C2}"/>
		<circle cx="24" cy="5" r="1.5" fill="{C2}"/>
		<circle cx="15" cy="7" r="1.2" fill="{C2}"/>
		<circle cx="33" cy="6" r="1.2" fill="{C2}"/>
	</svg>""",

	"item_crimson_fruit": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="28" r="12" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.12"/>
		<path d="M24 17 C21 12 16 10 12 11 C13 16 18 19 24 19 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.20"/>
		<path d="M24 17 C27 12 32 10 36 11 C35 16 30 19 24 19 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.20"/>
		<path d="M24 17 L24 12" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M20 28 C22 25 26 25 28 28 C26 31 22 31 20 28 Z" fill="{C2}" fill-opacity="0.65"/>
		<circle cx="19" cy="24" r="1.4" fill="{C2}"/>
		<circle cx="29" cy="31" r="1.2" fill="{C2}"/>
	</svg>""",

	# ---- 批次 1：灵草 / 灵木 / 矿石独立造型
	"item_hansui": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M10 39 Q24 34 38 39" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 38 C23 31 22 25 23 18 C23 15 24 12 24 10 C25 12 26 15 26 18 C27 25 25 31 24 38 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M23 33 L18 29 L22 28 L16 23 L21 23 L17 18" stroke="{C1}" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M25 31 L30 27 L26 26 L32 21 L27 21 L31 16" stroke="{C1}" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M24 5 L30 11 L24 17 L18 11 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.28"/>
		<path d="M24 5 L24 17 M18 11 L30 11" stroke="{C2}" stroke-width="1.4" stroke-linecap="round"/>
		<circle cx="10" cy="33" r="1.4" fill="{C2}"/>
		<circle cx="38" cy="30" r="1.2" fill="{C2}"/>
	</svg>""",

	"item_xinghui": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 31 L24 40" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M10 27 C13 20 19 17 24 19 C29 17 35 20 38 27 C35 31 30 32 24 31 C18 32 13 31 10 27 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#6E558A" fill-opacity="0.22"/>
		<path d="M15 19 C17 13 21 11 24 13 C27 11 31 13 33 19 C30 22 27 23 24 22 C21 23 18 22 15 19 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#6E558A" fill-opacity="0.30"/>
		<path d="M13 27 C16 25 19 25 22 27 M26 27 C29 25 32 25 35 27" stroke="#A87424" stroke-width="1.3" stroke-linecap="round"/>
		<path d="M24 18 L20 13 M24 18 L28 13" stroke="#A87424" stroke-width="1.5" stroke-linecap="round"/>
		<circle cx="20" cy="12" r="1.3" fill="#A87424"/>
		<circle cx="28" cy="12" r="1.3" fill="#A87424"/>
		<circle cx="24" cy="9" r="1.6" fill="#A87424"/>
		<circle cx="12" cy="23" r="1.2" fill="#A87424"/>
		<circle cx="36" cy="23" r="1.2" fill="#A87424"/>
	</svg>""",

	"item_jiuye": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 40 L24 24" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 31 C16 31 10 26 9 20 C16 19 22 22 24 29 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.18"/>
		<path d="M24 31 C32 31 38 26 39 20 C32 19 26 22 24 29 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.18"/>
		<path d="M24 27 C18 25 15 19 16 13 C21 14 24 18 24 24 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
		<path d="M24 27 C30 25 33 19 32 13 C27 14 24 18 24 24 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.24"/>
		<path d="M24 23 C20 18 20 12 24 8 C28 12 28 18 24 23 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.30"/>
		<path d="M24 31 L17 24 M24 31 L31 24 M24 27 L20 17 M24 27 L28 17" stroke="{C2}" stroke-width="1.2" stroke-linecap="round"/>
		<circle cx="24" cy="6" r="2.6" stroke="{C1}" stroke-width="1.6" fill="#A87424" fill-opacity="0.55"/>
	</svg>""",

	"item_ironwood": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M 10.2 22.5 L 15.8 18.2 L 13.5 14.2 L 17 11.8 L 20.4 14.7 L 27.2 9.5 A 9.5 9.5 0 0 1 38.8 24.5 L 21.8 37.5 A 9.5 9.5 0 0 0 10.2 22.5 Z" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.4" stroke-linejoin="round"/>
		<path d="M 21.5 19.5 L 29.5 13.5 M 25.8 23.2 L 35.2 16.2 M 26.8 29.2 L 34.8 23.2" fill="none" stroke="{C1}" stroke-width="1.6" stroke-linecap="round" stroke-opacity="0.65"/>
		<circle cx="16" cy="30" r="9.5" fill="{C2}" fill-opacity="0.12" stroke="{C1}" stroke-width="2.4"/>
		<circle cx="16" cy="30" r="6.4" fill="none" stroke="{C1}" stroke-width="1.3" stroke-opacity="0.5"/>
		<polygon points="16,26.1 19.4,28.05 19.4,31.95 16,33.9 12.6,31.95 12.6,28.05" fill="{C2}" fill-opacity="0.88" stroke="{C1}" stroke-width="1.7" stroke-linejoin="round"/>
		<path d="M 14.6 29.2 L 16.2 27.8" fill="none" stroke="#FFFFFF" stroke-width="1.2" stroke-linecap="round" stroke-opacity="0.75"/>
	</svg>""",

	"item_thunderwood": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M 11 40.5 Q 14.5 32.5 14.5 23.5 L 13 17.5 L 17 19.5 L 19.5 15.5 L 21.5 23.5 L 28.5 17.5 L 31.5 20 L 30 25 Q 30 33 34.5 40.5 Q 22.5 42.5 11 40.5 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.4" stroke-linejoin="round" stroke-linecap="round"/>
		<path d="M 17 25.5 Q 18 32 15.5 38 M 27.2 25.5 Q 26.8 32 29 38" fill="none" stroke="{C1}" stroke-width="1.5" stroke-linecap="round" stroke-opacity="0.6"/>
		<path d="M 21.5 23.5 L 19.8 29 L 23.2 33.5 L 21.5 38.5" fill="none" stroke="{C2}" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
		<polygon points="27.5,5 33,5 27.5,12 32,12 21.5,23 24.8,14.5 20.5,14.5" fill="{C2}" fill-opacity="0.88" stroke="{C2}" stroke-width="1.4" stroke-linejoin="round"/>
		<path d="M 10.5 24 C 6.5 20 12.5 15 9 9.5" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round" stroke-opacity="0.75"/>
		<path d="M 35.5 26 C 39 22.5 35.5 18.5 38.5 14.5" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round" stroke-opacity="0.6"/>
	</svg>""",

	"item_icewood": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M 8 33 Q 17 24 34 13 L 38.5 15.5 L 36.5 19.5 Q 25 29 15 40 Q 9.5 39.5 8 33 Z" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.4" stroke-linejoin="round"/>
		<path d="M 8 33 Q 13.5 33.5 15 40" fill="none" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<circle cx="11.2" cy="36.6" r="1.4" fill="{C2}"/>
		<path d="M 16.5 31.5 Q 22.5 26 29.5 21" fill="none" stroke="{C1}" stroke-width="1.5" stroke-linecap="round" stroke-opacity="0.6"/>
		<polygon points="16,25.5 14.5,11.5 19.5,7.5 23,13 21.5,21.8" fill="{C2}" fill-opacity="0.32" stroke="{C2}" stroke-width="2.1" stroke-linejoin="round"/>
		<path d="M 19.5 7.5 L 18.8 21.5" fill="none" stroke="{C2}" stroke-width="1.3" stroke-linecap="round" stroke-opacity="0.75"/>
		<polygon points="24.5,19.5 27.5,7.5 32.5,10 30,15.8" fill="{C2}" fill-opacity="0.24" stroke="{C2}" stroke-width="2.0" stroke-linejoin="round"/>
		<polygon points="24.5,30 26.8,39.5 29.2,25.8" fill="{C2}" fill-opacity="0.34" stroke="{C2}" stroke-width="2.0" stroke-linejoin="round"/>
		<polygon points="31.5,23.8 33.8,32.5 35.8,20.1" fill="{C2}" fill-opacity="0.28" stroke="{C2}" stroke-width="1.9" stroke-linejoin="round"/>
		<path d="M 39 29.5 L 39 35.5 M 36 32.5 L 42 32.5" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round" stroke-opacity="0.8"/>
	</svg>""",

	"item_starwood": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M 10.5 27.5 L 33.5 18.5 A 7.1 7.1 0 0 1 38.5 31.5 L 15.5 40.5 A 7.1 7.1 0 0 0 10.5 27.5 Z" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.4" stroke-linejoin="round"/>
		<circle cx="13" cy="34" r="7" fill="{C2}" fill-opacity="0.10" stroke="{C1}" stroke-width="2.4"/>
		<circle cx="13" cy="34" r="4.4" fill="none" stroke="{C1}" stroke-width="1.2" stroke-opacity="0.45"/>
		<path d="M 13 31.2 L 13.8 33.2 L 15.8 34 L 13.8 34.8 L 13 36.8 L 12.2 34.8 L 10.2 34 L 12.2 33.2 Z" fill="{C2}"/>
		<path d="M 21.5 32.5 L 26.5 27.2 L 32 29.2 L 37 24.5" fill="none" stroke="{C2}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" stroke-opacity="0.85"/>
		<circle cx="21.5" cy="32.5" r="1.4" fill="{C2}"/>
		<circle cx="26.5" cy="27.2" r="1.6" fill="{C2}"/>
		<circle cx="32" cy="29.2" r="1.4" fill="{C2}"/>
		<circle cx="37" cy="24.5" r="1.5" fill="{C2}"/>
		<path d="M 23 22.6 Q 22.4 20.2 21.8 18.2" fill="none" stroke="{C1}" stroke-width="2.1" stroke-linecap="round"/>
		<path d="M 21.8 18.5 Q 15.2 18.8 10.8 14 Q 14.6 12.2 17 13 Q 17.2 8.6 20 6 Q 23.2 8.4 24.2 12.5 Q 27.6 11.2 31.2 12.2 Q 27.8 17.8 21.8 18.5 Z" fill="{C2}" fill-opacity="0.24" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
		<path d="M 21.8 18.2 L 20.2 9.5 M 21.2 15.6 L 14.5 14.2 M 22.2 15.2 L 27.8 13.2" fill="none" stroke="{C2}" stroke-width="1.3" stroke-linecap="round" stroke-opacity="0.85"/>
		<path d="M 38.5 7.5 L 39.5 10.5 L 42.5 11.5 L 39.5 12.5 L 38.5 15.5 L 37.5 12.5 L 34.5 11.5 L 37.5 10.5 Z" fill="{C2}" fill-opacity="0.9"/>
	</svg>""",

	"item_fusang": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M14 40 C9 33 16 29 13 23 C10 17 17 13 19 8 C23 14 21 18 25 21 C29 17 29 10 34 7 C39 14 34 22 30 26 C36 29 34 38 28 41 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<circle cx="24" cy="16" r="4.2" stroke="{C1}" stroke-width="1.8" fill="#A87424" fill-opacity="0.38"/>
		<path d="M24 7 L24 3 M24 25 L24 29 M16 16 L12 16 M32 16 L36 16 M18 10 L15 7 M30 10 L33 7 M18 22 L15 25 M30 22 L33 25" stroke="#A87424" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M24 35 C21 33 20 30 22 28 M24 33 C27 31 29 29 28 26" stroke="#A87424" stroke-width="1.4" stroke-linecap="round"/>
		<circle cx="24" cy="16" r="1.4" fill="#C2432D"/>
	</svg>""",

	"item_mithril": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 5 L34 15 L29 38 L18 40 L12 19 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#8A9BA8" fill-opacity="0.18"/>
		<path d="M12 19 L7 26 L18 40 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.20"/>
		<path d="M34 15 L41 24 L29 38 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.14"/>
		<path d="M24 5 L24 20 L18 40 M24 20 L29 38 M12 19 L24 20 L34 15" stroke="#8A9BA8" stroke-width="1.4" stroke-linejoin="round"/>
		<circle cx="24" cy="26" r="1.5" fill="#2A6B8C"/>
		<circle cx="17" cy="16" r="1.1" fill="#8A9BA8"/>
	</svg>""",

	"item_redgold": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M8 25 L15 13 L29 9 L41 18 L38 34 L23 41 L11 36 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#9A6B2F" fill-opacity="0.18"/>
		<path d="M12 27 L21 18 L28 25 L35 15" stroke="#C2432D" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M17 35 L26 27 L33 34" stroke="#A87424" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M21 18 L26 27 M28 25 L33 34" stroke="#C2432D" stroke-width="1.4" stroke-linecap="round"/>
		<circle cx="15" cy="30" r="1.4" fill="#C2432D"/>
		<circle cx="31" cy="19" r="1.2" fill="#A87424"/>
		<circle cx="35" cy="28" r="1.0" fill="#C2432D"/>
	</svg>""",

	"item_stariron": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M9 20 L17 9 L31 11 L40 21 L36 36 L22 41 L11 34 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#52606D" fill-opacity="0.22"/>
		<ellipse cx="18" cy="22" rx="3.2" ry="2.4" stroke="{C1}" stroke-width="1.2" fill="#2C2824" fill-opacity="0.22"/>
		<ellipse cx="29" cy="31" rx="2.6" ry="2.0" stroke="{C1}" stroke-width="1.2" fill="#2C2824" fill-opacity="0.20"/>
		<ellipse cx="30" cy="18" rx="1.8" ry="1.2" stroke="{C1}" stroke-width="1.0" fill="#2C2824" fill-opacity="0.18"/>
		<path d="M25 10 L27 17 L34 19 L27 21 L25 28 L23 21 L16 19 L23 17 Z" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round" fill="#A87424" fill-opacity="0.45"/>
		<circle cx="13" cy="30" r="1.0" fill="#A87424"/>
	</svg>""",

	"item_primordial_crystal": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M17 11 L22 15 L22 34 L17 30 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="#88BFA8" fill-opacity="0.22"/>
		<path d="M23 5 L30 10 L30 36 L23 41 L23 5 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.18"/>
		<path d="M31 14 L36 18 L36 31 L31 35 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="#88BFA8" fill-opacity="0.26"/>
		<path d="M23 5 L23 41 M26 8 L26 38 M17 11 L17 30 M31 14 L31 35" stroke="#88BFA8" stroke-width="1.2" stroke-linecap="round"/>
		<circle cx="11" cy="16" r="1.3" fill="{C2}"/>
		<circle cx="39" cy="25" r="1.1" fill="#88BFA8"/>
		<circle cx="24" cy="44" r="1.0" fill="{C2}"/>
	</svg>""",

	"item_taixu_gold": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 7 L34 23 L24 41 L14 23 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#A87424" fill-opacity="0.18"/>
		<path d="M24 13 L29 23 L24 35 L19 23 Z" stroke="{C1}" stroke-width="1.5" stroke-linejoin="round" fill="#A87424" fill-opacity="0.45"/>
		<path d="M7 23 C9 14 15 8 24 7" stroke="#6E558A" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M41 23 C39 32 33 38 24 41" stroke="#6E558A" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M10 18 C13 12 18 9 24 8" stroke="#6E558A" stroke-width="1.0" stroke-linecap="round"/>
		<circle cx="24" cy="23" r="1.6" fill="#A87424"/>
		<circle cx="8" cy="16" r="1.4" fill="#6E558A"/>
		<circle cx="40" cy="31" r="1.2" fill="#6E558A"/>
		<circle cx="35" cy="9" r="1.0" fill="#A87424"/>
	</svg>""",

	# ---- 批次 2：灵种与特殊材料
	"seed_ninglu": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 9 C31 17 35 24 32 32 C30 39 18 39 16 32 C13 24 17 17 24 9 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.16"/>
		<path d="M24 9 L24 4" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M24 3 C27 7 27 10 24 13 C21 10 21 7 24 3 Z" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.62"/>
		<path d="M12 35 C16 39 32 39 36 35" stroke="{C2}" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M9 38 C14 42 34 42 39 38" stroke="{C2}" stroke-width="1.2" stroke-linecap="round"/>
		<path d="M19 23 C20 28 21 32 24 34" stroke="#2A6B8C" stroke-width="1.4" stroke-linecap="round"/>
		<circle cx="19" cy="19" r="1.2" fill="#2A6B8C"/>
	</svg>""",

	"seed_spirit_berry": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 7 C35 7 41 16 39 26 C37 36 29 41 21 38 C13 35 8 26 11 17 C14 9 18 7 24 7 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#C2432D" fill-opacity="0.14"/>
		<path d="M24 15 L20 21 L25 23 L21 29 L27 31 L23 36" stroke="{C1}" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
		<circle cx="24" cy="25" r="5" stroke="{C1}" stroke-width="1.6" fill="#A87424" fill-opacity="0.45"/>
		<path d="M24 18 L24 32 M17 25 L31 25 M19 20 L29 30 M29 20 L19 30" stroke="#A87424" stroke-width="1.2" stroke-linecap="round"/>
		<path d="M12 20 C10 16 11 12 14 10" stroke="{C2}" stroke-width="1.4" stroke-linecap="round"/>
	</svg>""",

	"seed_ziyun": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<ellipse cx="24" cy="28" rx="9" ry="10" stroke="{C1}" stroke-width="2.2" fill="#6E558A" fill-opacity="0.18"/>
		<path d="M15 25 C15 18 19 13 24 12 C29 13 33 18 33 25" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M15 27 C9 27 5 23 7 18 C9 14 14 15 17 19 C19 21 18 24 15 25" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#6E558A" fill-opacity="0.12"/>
		<path d="M33 27 C39 27 43 23 41 18 C39 14 34 15 31 19 C29 21 30 24 33 25" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#6E558A" fill-opacity="0.12"/>
		<path d="M24 12 L24 8" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
		<circle cx="24" cy="7" r="2" fill="#6E558A"/>
		<path d="M20 30 C22 32 26 32 28 30" stroke="#6E558A" stroke-width="1.2" stroke-linecap="round"/>
	</svg>""",

	"seed_chiyan": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 5 C31 13 34 22 31 31 C29 38 21 41 17 35 C12 27 17 17 24 5 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#C2432D" fill-opacity="0.14"/>
		<path d="M24 15 C28 21 28 27 25 31 C22 34 19 30 20 26 C20 22 22 18 24 15 Z" stroke="{C1}" stroke-width="1.5" stroke-linejoin="round" fill="#A87424" fill-opacity="0.40"/>
		<path d="M24 5 C25 10 27 13 29 16" stroke="#A87424" stroke-width="1.2" stroke-linecap="round"/>
		<path d="M17 35 C15 38 16 41 19 42" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
		<circle cx="25" cy="24" r="1.2" fill="#A87424"/>
	</svg>""",

	"seed_hansui": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<polygon points="24,4 36,14 33,32 24,44 15,32 12,14" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.18"/>
		<path d="M24 10 L24 38 M16 20 L32 32 M32 20 L16 32" stroke="#88B8CC" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M24 4 L24 12 M12 14 L18 18 M36 14 L30 18" stroke="{C1}" stroke-width="1.4" stroke-linecap="round"/>
		<circle cx="24" cy="25" r="1.6" fill="#2A6B8C"/>
	</svg>""",

	"seed_xinghui": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M11 31 C8 19 15 9 26 7 C32 6 37 9 39 14 C33 11 27 12 22 16 C17 20 15 26 16 31 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#6E558A" fill-opacity="0.18"/>
		<circle cx="30" cy="27" r="8" stroke="{C1}" stroke-width="2.2" fill="#6E558A" fill-opacity="0.16"/>
		<path d="M30 20 L32 25 L37 27 L32 29 L30 34 L28 29 L23 27 L28 25 Z" stroke="{C1}" stroke-width="1.2" stroke-linejoin="round" fill="#A87424" fill-opacity="0.55"/>
		<path d="M12 32 C18 38 28 40 35 36" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
		<circle cx="38" cy="18" r="1.2" fill="#A87424"/>
		<circle cx="20" cy="36" r="1.0" fill="#A87424"/>
	</svg>""",

	"seed_jiuye": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 8 C31 12 32 21 27 27 C25 29 23 29 21 27 C16 21 17 12 24 8 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.18"/>
		<path d="M24 27 L24 34" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M24 33 C18 33 14 29 13 25 C18 24 22 27 24 31 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.20"/>
		<path d="M24 33 C30 33 34 29 35 25 C30 24 26 27 24 31 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.20"/>
		<path d="M24 31 C21 28 20 24 21 20 C24 21 25 25 24 29 Z" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round" fill="{C2}" fill-opacity="0.26"/>
		<circle cx="24" cy="6" r="2.2" stroke="{C1}" stroke-width="1.2" fill="#A87424" fill-opacity="0.60"/>
		<path d="M20 15 C22 18 22 22 24 25" stroke="{C2}" stroke-width="1.2" stroke-linecap="round"/>
	</svg>""",

	"item_star_core": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="10" stroke="{C1}" stroke-width="2.2" fill="#2A6B8C" fill-opacity="0.16"/>
		<path d="M8 18 C16 30 32 30 40 18" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M8 30 C16 18 32 18 40 30" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M24 12 L25.5 21 L34 24 L25.5 27 L24 36 L22.5 27 L14 24 L22.5 21 Z" stroke="{C1}" stroke-width="1.2" stroke-linejoin="round" fill="#A87424" fill-opacity="0.42"/>
		<circle cx="9" cy="13" r="1.3" fill="#A87424"/>
		<circle cx="39" cy="35" r="1.2" fill="#2A6B8C"/>
		<circle cx="37" cy="12" r="1.0" fill="#A87424"/>
		<circle cx="12" cy="36" r="1.0" fill="#2A6B8C"/>
	</svg>""",

	"item_thunder_essence": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<polygon points="24,5 33,20 24,31 15,20" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#6E558A" fill-opacity="0.24"/>
		<path d="M24 10 L24 26 M19 20 L29 20" stroke="#A87424" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M7 12 L13 18 L9 24 L16 30 L12 38" stroke="#6E558A" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M41 10 L35 17 L39 23 L32 29 L36 40" stroke="#6E558A" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M11 7 L17 12 L13 16" stroke="#A87424" stroke-width="1.2" stroke-linecap="round"/>
		<circle cx="24" cy="20" r="1.8" fill="#A87424"/>
	</svg>""",

	"item_ancient_soul": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M20 42 C10 38 12 30 18 26 C24 22 20 16 24 10 C27 15 30 18 28 22 C34 20 36 25 33 29 C38 31 38 38 30 41 C34 36 30 33 26 35 C22 37 24 40 20 42 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#2A6F62" fill-opacity="0.14"/>
		<path d="M23 35 C17 33 18 27 23 24 C27 21 26 17 28 14" stroke="{C1}" stroke-width="1.4" stroke-linecap="round"/>
		<circle cx="24" cy="27" r="3.2" stroke="{C1}" stroke-width="1.6" fill="#52606D" fill-opacity="0.30"/>
		<circle cx="24" cy="27" r="1.2" fill="#2A6F62"/>
		<path d="M13 38 C16 41 21 42 24 42" stroke="#52606D" stroke-width="1.2" stroke-linecap="round"/>
		<circle cx="31" cy="13" r="1.2" fill="#2A6F62"/>
	</svg>""",

	# ---- 批次 3：丹药 / 符箓 / 真龙残鳞
	"item_peiyuan_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M22 7 L26 7 M22 7 C20 10 20 12 23 14 C19 16 16 21 16 28 C16 36 20 41 24 41 C28 41 32 36 32 28 C32 21 29 16 25 14 C28 12 28 10 26 7" stroke="{C1}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" fill="#2A6F62" fill-opacity="0.14"/>
		<path d="M17 29 C20 25 24 31 28 27 C30 25 31 27 31 29" stroke="#2A6F62" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M18 25 C21 23 24 25 24 28 C24 31 21 33 18 31" stroke="#2A6F62" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M21 18 C23 20 25 20 27 18" stroke="#2A6F62" stroke-width="1.4" stroke-linecap="round"/>
	</svg>""",

	"item_gold_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="25" r="12" stroke="{C1}" stroke-width="2.2" fill="#A87424" fill-opacity="0.20"/>
		<path d="M15 20 C19 15 27 14 33 18" stroke="#A87424" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M14 25 C20 20 30 20 35 25" stroke="#A87424" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M15 30 C20 35 29 35 33 31" stroke="#A87424" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M23 14 C21 20 21 30 23 36" stroke="#A87424" stroke-width="1.2" stroke-linecap="round"/>
		<path d="M11 12 L13 14 M37 12 L35 14 M24 7 L24 9" stroke="#A87424" stroke-width="1.6" stroke-linecap="round"/>
		<circle cx="18" cy="19" r="1.2" fill="#A87424"/>
	</svg>""",

	"item_yuanying_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="17" r="8" stroke="{C1}" stroke-width="2.2" fill="#6E558A" fill-opacity="0.18"/>
		<path d="M16 28 C11 31 11 38 17 40 C19 35 20 31 22 28 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#6E558A" fill-opacity="0.14"/>
		<path d="M32 28 C37 31 37 38 31 40 C29 35 28 31 26 28 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#6E558A" fill-opacity="0.14"/>
		<path d="M21 27 C18 32 18 37 21 41 L24 38 L27 41 C30 37 30 32 27 27 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#6E558A" fill-opacity="0.10"/>
		<path d="M24 5 L25.5 10 L30 11.5 L25.5 13 L24 18 L22.5 13 L18 11.5 L22.5 10 Z" stroke="{C1}" stroke-width="1.2" stroke-linejoin="round" fill="#A87424" fill-opacity="0.55"/>
		<circle cx="24" cy="17" r="1.6" fill="#A87424"/>
	</svg>""",

	"item_big_heal": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M19 7 L29 7 M21 7 L21 12 C15 14 12 19 12 26 C12 35 18 41 24 41 C30 41 36 35 36 26 C36 19 33 14 27 12 L27 7" stroke="{C1}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" fill="#2E7D5B" fill-opacity="0.14"/>
		<path d="M24 18 C20 22 20 27 24 31 C28 27 28 22 24 18 Z" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round" fill="#2E7D5B" fill-opacity="0.30"/>
		<path d="M20 24 C23 25 25 27 26 31 M28 24 C25 25 23 27 22 31" stroke="#2E7D5B" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M17 33 C20 31 28 31 31 33" stroke="#2E7D5B" stroke-width="1.4" stroke-linecap="round"/>
	</svg>""",

	"item_heart_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<polygon points="24,5 38,13 38,30 24,43 10,30 10,13" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#2E7D5B" fill-opacity="0.14"/>
		<path d="M24 17 C18 17 15 22 18 27 C20 30 24 32 24 35 C24 32 28 30 30 27 C33 22 30 17 24 17 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#C2432D" fill-opacity="0.20"/>
		<path d="M24 21 L24 30 M20 25 L28 25" stroke="#C2432D" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M14 16 L17 18 M34 16 L31 18" stroke="#2E7D5B" stroke-width="1.2" stroke-linecap="round"/>
	</svg>""",

	"item_revive_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="23" r="8" stroke="{C1}" stroke-width="2.2" fill="#A87424" fill-opacity="0.18"/>
		<path d="M8 31 C5 27 6 22 10 20 C12 16 18 16 20 20 C22 18 26 18 28 20 C30 16 36 16 38 20 C42 22 43 27 40 31 C36 29 33 30 30 33 C27 31 21 31 18 33 C15 30 12 29 8 31 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#A87424" fill-opacity="0.10"/>
		<path d="M24 19 L24 27 M20 23 L28 23" stroke="#2E7D5B" stroke-width="2.2" stroke-linecap="round"/>
		<circle cx="24" cy="23" r="1.2" fill="#A87424"/>
	</svg>""",

	"item_jindan_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="19" r="9" stroke="{C1}" stroke-width="2.2" fill="#A87424" fill-opacity="0.22"/>
		<path d="M18 14 C21 18 27 18 30 15 M18 23 C21 20 27 20 30 23" stroke="#A87424" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M13 41 C10 35 14 32 13 28 C17 30 19 34 18 37 C22 35 22 30 25 27 C26 33 30 35 29 40 C26 43 18 44 13 41 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="#C2432D" fill-opacity="0.18"/>
		<path d="M24 7 L24 4" stroke="#A87424" stroke-width="1.6" stroke-linecap="round"/>
		<circle cx="19" cy="16" r="1.2" fill="#A87424"/>
	</svg>""",

	"item_nascent_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="8" stroke="{C1}" stroke-width="2.2" fill="#2A6B8C" fill-opacity="0.12"/>
		<path d="M10 24 C10 14 17 8 27 9" stroke="#2A6B8C" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M38 24 C38 34 31 40 21 39" stroke="#6E558A" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M18 24 C18 21 20 19 23 19 C26 19 28 21 28 24 C28 27 26 29 23 29 C21 29 19 27 18 25" stroke="#6E558A" stroke-width="1.4" stroke-linecap="round"/>
		<circle cx="24" cy="24" r="2" fill="#6E558A" fill-opacity="0.65"/>
	</svg>""",

	"item_ascension_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="27" r="8" stroke="{C1}" stroke-width="2.2" fill="#A87424" fill-opacity="0.22"/>
		<path d="M8 21 C16 29 32 29 40 21" stroke="#6E558A" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M12 9 C14 5 20 4 22 7 C25 4 31 5 32 9 C35 7 38 9 38 12 C33 14 15 14 10 12 C9 11 10 10 12 9 Z" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round" fill="#6E558A" fill-opacity="0.14"/>
		<path d="M23 13 L21 19 L25 20 L22 26" stroke="#A87424" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M24 31 L25.5 35 L30 36.5 L25.5 38 L24 42 L22.5 38 L18 36.5 L22.5 35 Z" stroke="{C1}" stroke-width="1.2" stroke-linejoin="round" fill="#A87424" fill-opacity="0.50"/>
	</svg>""",

	"item_turtle_talisman": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M8 9 L40 9 L38 27 C36 35 30 41 24 44 C18 41 12 35 10 27 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#52606D" fill-opacity="0.14"/>
		<path d="M24 15 L32 20 L32 29 L24 34 L16 29 L16 20 Z" stroke="#9A6B2F" stroke-width="1.6" stroke-linejoin="round"/>
		<path d="M24 20 L28 22 L28 27 L24 29 L20 27 L20 22 Z" stroke="#9A6B2F" stroke-width="1.2" stroke-linejoin="round"/>
		<path d="M24 15 L24 20 M32 20 L28 22 M32 29 L28 27 M24 34 L24 29 M16 29 L20 27 M16 20 L20 22" stroke="#9A6B2F" stroke-width="1.0" stroke-linecap="round"/>
		<circle cx="24" cy="24" r="1.4" fill="#52606D"/>
	</svg>""",

	"item_taiji_talisman": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="13" y="5" width="22" height="38" rx="6" stroke="{C1}" stroke-width="2.2" fill="#A87424" fill-opacity="0.14"/>
		<circle cx="24" cy="24" r="7" stroke="{C1}" stroke-width="1.8"/>
		<path d="M24 17 A7 7 0 0 1 24 31 A3.5 3.5 0 0 0 24 24 A3.5 3.5 0 0 1 24 17 Z" stroke="{C1}" stroke-width="1.2" fill="#A87424" fill-opacity="0.35"/>
		<circle cx="24" cy="20.5" r="1.4" fill="#A87424"/>
		<circle cx="24" cy="27.5" r="1.4" fill="#F6EEDC"/>
		<path d="M4 24 L9 24 M39 24 L44 24 M8 14 L11 17 M40 14 L37 17 M8 34 L11 31 M40 34 L37 31" stroke="#A87424" stroke-width="1.4" stroke-linecap="round"/>
	</svg>""",

	"item_taixu_shield": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<polygon points="24,4 39,15 35,33 24,44 13,33 9,15" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#6E558A" fill-opacity="0.14"/>
		<polygon points="24,11 33,18 30,31 24,37 18,31 15,18" stroke="#A87424" stroke-width="1.6" stroke-linejoin="round" fill="none"/>
		<path d="M24 17 L25.5 22 L31 23.5 L25.5 25 L24 30 L22.5 25 L17 23.5 L22.5 22 Z" stroke="{C1}" stroke-width="1.2" stroke-linejoin="round" fill="#A87424" fill-opacity="0.50"/>
		<path d="M7 22 C5 26 5 30 8 34 M41 22 C43 26 43 30 40 34" stroke="#6E558A" stroke-width="1.4" stroke-linecap="round"/>
		<circle cx="24" cy="23.5" r="1.2" fill="#A87424"/>
	</svg>""",

	"item_zixiao_talisman": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M14 5 L34 5 L34 15 L30 15 L30 39 L18 39 L18 15 L14 15 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#C2432D" fill-opacity="0.10"/>
		<path d="M17 9 L31 9" stroke="#C2432D" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M20 19 L28 27 L22 28 L30 38" stroke="#6E558A" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M26 19 L18 27" stroke="#6E558A" stroke-width="1.6" stroke-linecap="round"/>
		<circle cx="24" cy="12" r="1.6" fill="#C2432D"/>
	</svg>""",

	"item_taixu_thunder": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 6 L30 13 L30 33 L24 42 L18 33 L18 13 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.14"/>
		<path d="M14 8 C16 4 22 4 24 7 C26 4 32 4 34 8 C36 6 38 8 37 11 C32 13 16 13 11 11 C10 10 12 8 14 8 Z" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.12"/>
		<path d="M24 12 L20 22 L26 24 L21 34" stroke="#A87424" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M19 17 L29 17" stroke="#A87424" stroke-width="1.2" stroke-linecap="round"/>
	</svg>""",

	"item_dragon_scale": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 5 C35 8 42 17 42 27 L38 29 L41 33 C38 38 32 41 24 43 C14 42 6 36 6 27 C6 17 13 8 24 5 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#C2432D" fill-opacity="0.16"/>
		<path d="M24 9 C28 16 30 24 29 37" stroke="#A87424" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M16 16 C18 20 19 25 18 31 M32 16 C30 20 29 25 30 31" stroke="#A87424" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M13 23 C17 25 21 25 24 23 M35 23 C31 25 27 25 24 23" stroke="#C2432D" stroke-width="1.2" stroke-linecap="round"/>
		<circle cx="24" cy="10" r="1.2" fill="#A87424"/>
	</svg>""",

	# ---- 批次 4：飞剑与法袍 / 甲胄
	"equip_mithril_sword": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 4 L28 12 L27 30 L24 34 L21 30 L20 12 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#8A9BA8" fill-opacity="0.18"/>
		<path d="M24 6 L24 31" stroke="#2A6B8C" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M16 30 C12 27 9 28 7 31 C11 34 16 34 21 32" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.10"/>
		<path d="M32 30 C36 27 39 28 41 31 C37 34 32 34 27 32" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.10"/>
		<path d="M24 34 L24 41 M21 41 L27 41" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<circle cx="24" cy="43" r="1.8" stroke="{C1}" stroke-width="1.6"/>
		<path d="M21 9 C18 17 19 26 23 31" stroke="#2A6B8C" stroke-width="1.5" stroke-linecap="round"/>
	</svg>""",

	"equip_redgold_sword": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M19 4 L29 4 L32 27 L24 35 L16 27 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#C2432D" fill-opacity="0.16"/>
		<path d="M24 6 L24 32 M20 9 L18 26 M28 9 L30 26" stroke="#A87424" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M12 28 L20 31 L18 36 L14 32 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#A87424" fill-opacity="0.24"/>
		<path d="M36 28 L28 31 L30 36 L34 32 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#A87424" fill-opacity="0.24"/>
		<path d="M24 35 L24 42 M20 42 L28 42" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<circle cx="24" cy="44" r="1.5" fill="#C2432D"/>
	</svg>""",

	"equip_star_sword": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M22 4 L26 4 L27 29 L24 34 L21 29 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.14"/>
		<path d="M24 5 L24 30" stroke="#8A9BA8" stroke-width="1.2" stroke-linecap="round"/>
		<path d="M14 31 C18 36 30 36 34 31" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M24 34 L24 42" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<circle cx="24" cy="43" r="1.6" stroke="{C1}" stroke-width="1.4"/>
		<path d="M36 8 L37 12 L41 13 L37 14 L36 18 L35 14 L31 13 L35 12 Z" stroke="{C1}" stroke-width="1.0" stroke-linejoin="round" fill="#A87424" fill-opacity="0.55"/>
		<path d="M39 23 L40 25 L42 26 L40 27 L39 29 L38 27 L36 26 L38 25 Z" fill="#A87424" fill-opacity="0.55"/>
	</svg>""",

	"equip_primordial_sword": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M21 4 L27 4 L30 23 L24 34 L18 23 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#2E7D5B" fill-opacity="0.10"/>
		<path d="M23 9 L25 9 L26 21 L24 26 L22 21 Z" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round" fill="none"/>
		<path d="M15 24 L21 26 L18 30 L13 27 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#A87424" fill-opacity="0.22"/>
		<path d="M33 24 L27 26 L30 30 L35 27 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#A87424" fill-opacity="0.22"/>
		<rect x="21" y="27" width="6" height="11" rx="2" stroke="{C1}" stroke-width="1.8" fill="#2E7D5B" fill-opacity="0.18"/>
		<circle cx="24" cy="32" r="2.2" stroke="#A87424" stroke-width="1.6"/>
		<path d="M21 38 C18 41 16 43 13 44 M27 38 C30 41 32 43 35 44" stroke="#2E7D5B" stroke-width="1.6" stroke-linecap="round"/>
		<circle cx="13" cy="44" r="1.2" fill="#A87424"/>
		<circle cx="35" cy="44" r="1.2" fill="#A87424"/>
	</svg>""",

	"equip_taixu_sword": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 3 L28 10 L27 28 L24 33 L21 28 L20 10 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#6E558A" fill-opacity="0.12"/>
		<path d="M24 4 L24 30" stroke="#A87424" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M15 29 L21 31 L18 36 L13 32 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#A87424" fill-opacity="0.22"/>
		<path d="M33 29 L27 31 L30 36 L35 32 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#A87424" fill-opacity="0.22"/>
		<path d="M24 33 L24 40 M21 40 L27 40" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<circle cx="24" cy="43" r="2" stroke="{C1}" stroke-width="1.4" fill="#A87424" fill-opacity="0.30"/>
		<ellipse cx="24" cy="15" rx="13" ry="5" stroke="#6E558A" stroke-width="1.6"/>
		<path d="M9 12 C5 16 5 22 9 26 M39 12 C43 16 43 22 39 26" stroke="#6E558A" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M17 7 C19 4 22 5 23 8 M31 7 C29 4 26 5 25 8" stroke="#A87424" stroke-width="1.2" stroke-linecap="round"/>
	</svg>""",

	"equip_mithril_armor": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M16 11 L22 8 L26 8 L32 11 L37 19 L34 39 L14 39 L11 19 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#52606D" fill-opacity="0.14"/>
		<path d="M11 19 L6 23 L9 31 L14 27 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#52606D" fill-opacity="0.24"/>
		<path d="M37 19 L42 23 L39 31 L34 27 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#52606D" fill-opacity="0.24"/>
		<path d="M16 11 L12 16 L18 19 Z" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round" fill="#52606D" fill-opacity="0.20"/>
		<path d="M32 11 L36 16 L30 19 Z" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round" fill="#52606D" fill-opacity="0.20"/>
		<path d="M24 20 L29 23 L29 29 L24 32 L19 29 L19 23 Z" stroke="#2A6B8C" stroke-width="1.6" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.20"/>
		<path d="M24 22 L24 30 M20 26 L28 26" stroke="#2A6B8C" stroke-width="1.2" stroke-linecap="round"/>
		<path d="M16 35 L32 35" stroke="#2A6B8C" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	"equip_redgold_robe": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M18 10 L24 14 L30 10 L36 13 L43 25 L35 29 L37 40 L11 40 L13 29 L5 25 L12 13 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#C2432D" fill-opacity="0.12"/>
		<path d="M18 11 L24 24 L30 11" stroke="#A87424" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M14 28 L34 28" stroke="#A87424" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M16 37 C18 34 20 36 21 39 C23 36 25 38 26 40 C28 37 30 35 32 38" stroke="#C2432D" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M13 29 L11 36 M35 29 L37 36" stroke="#A87424" stroke-width="1.2" stroke-linecap="round"/>
		<circle cx="24" cy="28" r="1.5" fill="#A87424"/>
	</svg>""",

	"equip_ice_armor": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M17 13 L23 10 L25 10 L31 13 L35 22 L32 39 L16 39 L13 22 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.14"/>
		<path d="M13 20 L7 16 L10 26 L14 24 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.24"/>
		<path d="M35 20 L41 16 L38 26 L34 24 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.24"/>
		<path d="M24 18 L30 24 L24 32 L18 24 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#88B8CC" fill-opacity="0.28"/>
		<path d="M24 20 L24 30 M20 24 L28 24" stroke="#88B8CC" stroke-width="1.2" stroke-linecap="round"/>
		<path d="M16 34 L32 34" stroke="#2A6B8C" stroke-width="1.6" stroke-linecap="round"/>
		<circle cx="24" cy="24" r="1.2" fill="#88B8CC"/>
	</svg>""",

	"equip_primordial_robe": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M19 8 L24 12 L29 8 L30 15 L38 20 L35 28 L34 40 L14 40 L13 28 L10 20 L18 15 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#2E7D5B" fill-opacity="0.12"/>
		<path d="M19 9 L24 21 L29 9" stroke="#A87424" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M10 20 C14 16 18 18 19 22 C21 18 27 18 29 22 C30 18 34 16 38 20" stroke="#A87424" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M14 30 L34 30" stroke="#2E7D5B" stroke-width="2.0" stroke-linecap="round"/>
		<circle cx="24" cy="33" r="2.2" stroke="#A87424" stroke-width="1.6" fill="#2E7D5B" fill-opacity="0.20"/>
		<path d="M18 36 L24 39 L30 36" stroke="#A87424" stroke-width="1.4" stroke-linecap="round"/>
		<circle cx="15" cy="24" r="1.0" fill="#A87424"/>
		<circle cx="33" cy="24" r="1.0" fill="#A87424"/>
	</svg>""",

	"equip_taixu_robe": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M17 11 L24 15 L31 11 L38 16 L44 30 L36 33 L38 41 L10 41 L12 33 L4 30 L10 16 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#6E558A" fill-opacity="0.12"/>
		<path d="M19 12 L24 24 L29 12" stroke="#A87424" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M8 20 C2 24 6 30 12 28 C7 32 10 38 16 36" stroke="#6E558A" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M40 20 C46 24 42 30 36 28 C41 32 38 38 32 36" stroke="#6E558A" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M15 30 L33 30" stroke="#A87424" stroke-width="2.0" stroke-linecap="round"/>
		<circle cx="24" cy="30" r="2.2" stroke="{C1}" stroke-width="1.2" fill="#A87424" fill-opacity="0.40"/>
		<path d="M17 36 C20 38 28 38 31 36" stroke="#6E558A" stroke-width="1.4" stroke-linecap="round"/>
	</svg>""",

	# ---- 批次 5：仙坊法器 / 工具 / 洞府扩建
	"tool_hoe_jade": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M10 40 L30 17" stroke="{C1}" stroke-width="2.6" stroke-linecap="round"/>
		<path d="M15 35 L18 32 M21 28 L24 25 M27 21 L30 18" stroke="#2E7D5B" stroke-width="1.2" stroke-linecap="round"/>
		<path d="M22 16 C28 10 38 12 42 19 C36 24 28 24 22 20 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#2E7D5B" fill-opacity="0.22"/>
		<path d="M26 19 C30 15 35 15 38 18" stroke="#2A6F62" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M32 17 C34 15 36 15 38 17" stroke="#2A6F62" stroke-width="1.0" stroke-linecap="round"/>
		<circle cx="24" cy="20" r="1.1" fill="#2A6F62"/>
	</svg>""",

	"tool_hoe_star": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M12 40 L28 20" stroke="{C1}" stroke-width="2.6" stroke-linecap="round"/>
		<circle cx="28" cy="20" r="3" stroke="#A87424" stroke-width="1.8" fill="#A87424" fill-opacity="0.12"/>
		<path d="M19 12 C26 6 36 10 38 18 C32 17 26 18 20 22 C18 18 18 15 19 12 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.18"/>
		<path d="M20 22 C25 19 31 17 38 18" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M41 7 L42 10 L45 11 L42 12 L41 15 L40 12 L37 11 L40 10 Z" stroke="{C1}" stroke-width="0.9" stroke-linejoin="round" fill="#A87424" fill-opacity="0.55"/>
		<circle cx="20" cy="12" r="1.1" fill="#A87424"/>
	</svg>""",

	"tool_axe_cold": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M10 40 L32 14" stroke="{C1}" stroke-width="2.8" stroke-linecap="round"/>
		<path d="M26 10 C36 10 42 17 40 25 C34 27 28 24 24 19 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#52606D" fill-opacity="0.22"/>
		<path d="M26 12 L20 7 L22 14 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#52606D" fill-opacity="0.22"/>
		<path d="M33 12 C36 17 36 21 34 24 M30 14 C32 18 32 21 31 23" stroke="#2A6B8C" stroke-width="1.4" stroke-linecap="round"/>
		<circle cx="27" cy="11" r="1.2" fill="#2A6B8C"/>
	</svg>""",

	"tool_axe_ice": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 8 L24 42" stroke="{C1}" stroke-width="2.6" stroke-linecap="round"/>
		<path d="M22 12 C14 10 7 15 6 24 L13 22 L8 30 L16 27 L14 34 L22 28 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.20"/>
		<path d="M26 12 C34 10 41 15 42 24 L35 22 L40 30 L32 27 L34 34 L26 28 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.20"/>
		<path d="M24 20 L29 26 L24 33 L19 26 Z" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round" fill="#88B8CC" fill-opacity="0.30"/>
		<path d="M24 22 L24 31" stroke="#88B8CC" stroke-width="1.2" stroke-linecap="round"/>
		<circle cx="24" cy="9" r="1.4" fill="#88B8CC"/>
	</svg>""",

	"tool_pick_gold": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M12 39 L31 15" stroke="{C1}" stroke-width="2.8" stroke-linecap="round"/>
		<path d="M14 10 L30 8 L40 20 L32 24 L27 16 L16 16 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#52606D" fill-opacity="0.22"/>
		<path d="M24 10 L32 16 L38 20" stroke="#A87424" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M18 13 L20 16 M23 12 L25 15" stroke="#A87424" stroke-width="1.2" stroke-linecap="round"/>
		<circle cx="36" cy="14" r="1.3" fill="#A87424"/>
	</svg>""",

	"tool_pick_primordial": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 42 L24 22" stroke="{C1}" stroke-width="2.6" stroke-linecap="round"/>
		<path d="M10 20 C14 10 20 8 24 12 C28 8 34 10 38 20 L32 20 C29 16 27 15 24 18 C21 15 19 16 16 20 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#2E7D5B" fill-opacity="0.16"/>
		<path d="M24 22 L29 28 L24 35 L19 28 Z" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round" fill="#2E7D5B" fill-opacity="0.24"/>
		<path d="M24 24 L24 33" stroke="#A87424" stroke-width="1.2" stroke-linecap="round"/>
		<circle cx="24" cy="29" r="1.2" fill="#A87424"/>
	</svg>""",

	"gear_furnace_bagua": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<polygon points="24,6 33,9 38,17 37,27 30,35 18,35 11,27 10,17 15,9" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#A87424" fill-opacity="0.14"/>
		<path d="M18 12 L30 12 M24 8 L24 12" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
		<circle cx="24" cy="23" r="6" stroke="#C2432D" stroke-width="1.4"/>
		<path d="M24 17 A6 6 0 0 1 24 29 A3 3 0 0 0 24 23 A3 3 0 0 1 24 17 Z" fill="#A87424" fill-opacity="0.35"/>
		<path d="M18 35 L15 41 M30 35 L33 41" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M19 42 C17 45 18 47 21 47 C23 45 22 43 24 42 C26 45 29 45 30 43 C32 46 29 48 27 47" stroke="#C2432D" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	"gear_furnace_ding": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M16 14 L32 14 L35 26 C35 34 30 39 24 39 C18 39 13 34 13 26 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#6E558A" fill-opacity="0.12"/>
		<path d="M16 14 C10 12 8 16 10 20 C12 22 15 21 16 19 M32 14 C38 12 40 16 38 20 C36 22 33 21 32 19" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="#A87424" fill-opacity="0.16"/>
		<path d="M18 39 L16 45 M24 39 L24 45 M30 39 L32 45" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M18 24 C22 27 26 27 30 24" stroke="#A87424" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M20 9 C18 5 22 3 20 2 M27 10 C29 6 25 3 28 2" stroke="#6E558A" stroke-width="1.4" stroke-linecap="round"/>
		<circle cx="24" cy="10" r="1.2" fill="#A87424"/>
	</svg>""",

	"gear_furnace_taixu": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<ellipse cx="24" cy="27" rx="14" ry="10" stroke="{C1}" stroke-width="2.2" fill="#2A6B8C" fill-opacity="0.14"/>
		<path d="M14 19 C16 12 32 12 34 19" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="#6E558A" fill-opacity="0.14"/>
		<circle cx="24" cy="11" r="2.6" stroke="{C1}" stroke-width="1.4" fill="#A87424" fill-opacity="0.45"/>
		<ellipse cx="24" cy="25" rx="20" ry="6" stroke="#6E558A" stroke-width="1.6"/>
		<path d="M12 34 C18 38 30 38 36 34" stroke="#2A6B8C" stroke-width="1.4" stroke-linecap="round"/>
		<circle cx="24" cy="27" r="3" stroke="#A87424" stroke-width="1.2"/>
		<circle cx="9" cy="18" r="1.2" fill="#6E558A"/>
		<circle cx="39" cy="33" r="1.0" fill="#A87424"/>
	</svg>""",

	"gear_bell_soul": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 4 L24 12 M20 6 L24 10 L28 6 M18 9 L24 12 L30 9" stroke="{C1}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M24 13 C18 14 16 20 16 27 C16 32 18 35 20 36 L28 36 C30 35 32 32 32 27 C32 20 30 14 24 13 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#6E558A" fill-opacity="0.16"/>
		<path d="M19 36 C20 39 22 40 24 40 C26 40 28 39 29 36" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M24 18 L24 32 M21 22 L27 22 M21 27 L27 27" stroke="#A87424" stroke-width="1.3" stroke-linecap="round"/>
		<circle cx="24" cy="38" r="1.4" fill="#A87424"/>
	</svg>""",

	"gear_bell_dao": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M13 20 C13 13 18 10 24 10 C30 10 35 13 35 20 L38 34 L10 34 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#52606D" fill-opacity="0.14"/>
		<path d="M20 10 C20 5 24 4 26 6 C29 4 32 6 30 9 C28 11 24 11 20 10 Z" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round" fill="#A87424" fill-opacity="0.20"/>
		<path d="M10 34 C14 38 34 38 38 34" stroke="#A87424" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M6 24 C4 28 4 31 6 34 M42 24 C44 28 44 31 42 34" stroke="#A87424" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M17 26 C20 28 28 28 31 26" stroke="#A87424" stroke-width="1.2" stroke-linecap="round"/>
	</svg>""",

	"farm_plot_3": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M5 21 L24 11 L43 21 L43 27 L24 37 L5 27 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#2E7D5B" fill-opacity="0.12"/>
		<path d="M5 30 L24 20 L43 30 L43 38 L24 45 L5 38 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#2E7D5B" fill-opacity="0.18"/>
		<path d="M15 20 L15 13 M15 17 C12 16 11 14 12 12 C14 12 15 14 15 16 M15 17 C18 16 19 14 18 12 C16 12 15 14 15 16" stroke="#2E7D5B" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M24 27 L24 20 M24 24 C21 23 20 21 21 19 C23 19 24 21 24 23 M24 24 C27 23 28 21 27 19 C25 19 24 21 24 23" stroke="#2E7D5B" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M33 20 L33 13 M33 17 C30 16 29 14 30 12 C32 12 33 14 33 16 M33 17 C36 16 37 14 36 12 C34 12 33 14 33 16" stroke="#2E7D5B" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M8 33 C14 35 18 37 22 40" stroke="#2A6B8C" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	"farm_plot_4": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M8 16 L24 8 L40 16 L40 32 L24 40 L8 32 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#2E7D5B" fill-opacity="0.12"/>
		<path d="M16 12 L16 36 M32 12 L32 36 M8 24 L40 24" stroke="#2E7D5B" stroke-width="1.2" stroke-linecap="round"/>
		<rect x="7" y="14" width="4" height="4" rx="1" stroke="{C1}" stroke-width="1.2" fill="#A87424" fill-opacity="0.30"/>
		<rect x="37" y="14" width="4" height="4" rx="1" stroke="{C1}" stroke-width="1.2" fill="#A87424" fill-opacity="0.30"/>
		<rect x="7" y="30" width="4" height="4" rx="1" stroke="{C1}" stroke-width="1.2" fill="#A87424" fill-opacity="0.30"/>
		<rect x="37" y="30" width="4" height="4" rx="1" stroke="{C1}" stroke-width="1.2" fill="#A87424" fill-opacity="0.30"/>
		<path d="M24 18 C21 21 21 25 24 28 C27 25 27 21 24 18 Z" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round" fill="#A87424" fill-opacity="0.30"/>
		<circle cx="24" cy="23" r="1.4" fill="#A87424"/>
	</svg>""",

	# ---- 批次 6：藏经阁功法
	"tech_alchemy_fire": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M8 14 C6 12 4 14 5 17 L5 31 C4 34 6 36 8 34 L40 34 C42 36 44 34 43 31 L43 17 C44 14 42 12 40 14 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="#C2432D" fill-opacity="0.10"/>
		<path d="M8 14 C10 18 10 30 8 34 M40 14 C38 18 38 30 40 34" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M24 16 C28 20 28 25 25 28 C22 30 19 27 20 24 C20 21 22 18 24 16 Z" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round" fill="#C2432D" fill-opacity="0.34"/>
		<path d="M17 25 C15 22 16 19 18 17 C19 20 20 23 19 26 Z" stroke="{C1}" stroke-width="1.2" stroke-linejoin="round" fill="#A87424" fill-opacity="0.20"/>
		<path d="M31 25 C33 22 32 19 30 17 C29 20 28 23 29 26 Z" stroke="{C1}" stroke-width="1.2" stroke-linejoin="round" fill="#A87424" fill-opacity="0.20"/>
		<circle cx="24" cy="23" r="1.6" fill="#A87424"/>
	</svg>""",

	"tech_herb_spirit": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="15" y="4" width="18" height="40" rx="4" stroke="{C1}" stroke-width="2.2" fill="#2E7D5B" fill-opacity="0.10"/>
		<path d="M18 9 L30 9 M18 35 L30 35" stroke="{C1}" stroke-width="1.2" stroke-linecap="round"/>
		<path d="M20 12 C26 16 26 22 20 26 C24 30 26 34 22 38" stroke="#2E7D5B" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M21 18 C18 16 17 13 19 11 C22 11 23 14 22 17 Z" stroke="{C1}" stroke-width="1.2" stroke-linejoin="round" fill="#2E7D5B" fill-opacity="0.30"/>
		<path d="M25 26 C28 24 30 21 28 19 C25 19 24 22 25 25 Z" stroke="{C1}" stroke-width="1.2" stroke-linejoin="round" fill="#2A6F62" fill-opacity="0.28"/>
		<circle cx="30" cy="31" r="1.3" fill="#2A6F62"/>
		<circle cx="18" cy="30" r="1.0" fill="#2E7D5B"/>
	</svg>""",

	"tech_thunder_step": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M5 34 C14 36 26 30 40 14" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M7 27 C18 30 28 24 39 9" stroke="#2A6B8C" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M18 12 L26 22 L20 23 L30 34" stroke="#6E558A" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M30 8 C34 5 39 6 40 10 C43 10 44 14 40 16 C37 18 33 15 32 13 C30 14 28 12 30 8 Z" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round" fill="#2A6B8C" fill-opacity="0.14"/>
		<path d="M10 39 L16 37 M13 42 L19 40" stroke="#6E558A" stroke-width="1.4" stroke-linecap="round"/>
	</svg>""",

	"tech_star_sword": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M6 10 L38 38" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M42 8 L10 36" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M8 12 L34 34" stroke="#A87424" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M40 10 L12 34" stroke="#2A6B8C" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M24 14 L26 22 L34 24 L26 26 L24 34 L22 26 L14 24 L22 22 Z" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round" fill="#A87424" fill-opacity="0.48"/>
		<path d="M24 14 L24 34" stroke="{C1}" stroke-width="1.2" stroke-linecap="round"/>
		<circle cx="36" cy="36" r="1.3" fill="#2A6B8C"/>
		<circle cx="10" cy="40" r="1.1" fill="#A87424"/>
	</svg>""",

	"tech_void_ward": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="26" r="15" stroke="{C1}" stroke-width="2.2" fill="#6E558A" fill-opacity="0.08"/>
		<rect x="14" y="16" width="20" height="20" rx="2" stroke="#52606D" stroke-width="1.8" fill="none"/>
		<path d="M24 16 L24 36 M14 26 L34 26" stroke="#52606D" stroke-width="1.2" stroke-linecap="round"/>
		<path d="M18 20 L22 24 M30 20 L26 24 M18 32 L22 28 M30 32 L26 28" stroke="#6E558A" stroke-width="1.2" stroke-linecap="round"/>
		<path d="M17 4 L22 9 L18 12 L24 16" stroke="#6E558A" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M28 4 C31 7 34 6 36 3" stroke="#6E558A" stroke-width="1.2" stroke-linecap="round"/>
	</svg>""",

	"tech_breath_cycle": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M11 26 C8 17 15 9 24 9 C30 9 35 12 37 17" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M37 17 L41 15 L40 21" stroke="{C1}" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
		<path d="M37 26 C40 35 33 41 24 41 C18 41 13 38 11 33" stroke="#2A6F62" stroke-width="2.2" stroke-linecap="round"/>
		<path d="M11 33 L7 35 L8 29" stroke="#2A6F62" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
		<circle cx="24" cy="25" r="5" stroke="#A87424" stroke-width="1.8" fill="#A87424" fill-opacity="0.18"/>
		<path d="M24 20 C27 23 27 27 24 30 C21 27 21 23 24 20 Z" stroke="{C1}" stroke-width="1.2" stroke-linejoin="round" fill="#2A6F62" fill-opacity="0.30"/>
	</svg>""",

	# ================= 化神~大乘（v4 高阶内容）=================
	"item_high_herb": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 41 L24 20" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
		<path d="M24 31 C16 31 11 26 11 19 C18 19 22 24 24 29" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.20"/>
		<path d="M24 27 C32 27 37 22 37 15 C30 15 26 20 24 25" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.20"/>
		<path d="M24 20 C21 15 22 10 24 7 C26 10 27 15 24 20 Z" stroke="{C2}" stroke-width="1.8" stroke-linejoin="round" fill="{C2}" fill-opacity="0.45"/>
		<circle cx="24" cy="6" r="1.5" fill="{C2}"/>
		<path d="M18 41 H30" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"item_high_wood": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M12 41 C12 25 18 13 31 9" stroke="{C1}" stroke-width="3.0" stroke-linecap="round"/>
		<path d="M31 9 C22 8 17 13 16 20 C23 21 28 16 31 9 Z" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="{C2}" fill-opacity="0.32"/>
		<path d="M22 18 C16 18 12 22 12 27 C17 27 21 23 22 18 Z" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round" fill="{C2}" fill-opacity="0.22"/>
		<ellipse cx="17" cy="39" rx="9" ry="3.4" stroke="{C1}" stroke-width="1.8" fill="{C2}" fill-opacity="0.18"/>
		<ellipse cx="17" cy="39" rx="4.6" ry="1.6" stroke="{C2}" stroke-width="1.3"/>
	</svg>""",

	"item_high_ore": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<polygon points="14,40 18,22 25,16 31,25 30,40" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.28"/>
		<polygon points="28,40 32,26 39,23 40,40" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round" fill="{C2}" fill-opacity="0.18"/>
		<path d="M25 16 L28 40 M32 26 L35 40" stroke="{C2}" stroke-width="1.3" stroke-linecap="round"/>
		<path d="M11 43 H39" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"item_high_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="26" r="11" stroke="{C1}" stroke-width="2.2" fill="{C2}" fill-opacity="0.32"/>
		<path d="M17 22 C20 26.5 28 26.5 31 22" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<circle cx="24" cy="26" r="4.2" stroke="{C2}" stroke-width="1.4"/>
		<path d="M24 6 C27.5 10 24 13 24 15" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
		<circle cx="14" cy="13" r="1.2" fill="{C2}"/>
		<circle cx="35" cy="10" r="1.0" fill="{C2}"/>
	</svg>""",

	"item_breakthrough_pill_high": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="12.5" stroke="{C1}" stroke-width="2.2" fill="{C1}" fill-opacity="0.10"/>
		<path d="M26 12 L18.5 25 L23.5 25 L20.5 36 L30.5 22 L25 22 Z" stroke="{C2}" stroke-width="1.4" stroke-linejoin="round" fill="{C2}" fill-opacity="0.60"/>
		<path d="M37 10 L40 13 M38.5 6.5 L38.5 15.5 M33 11 L42 11" stroke="{C2}" stroke-width="1.2" stroke-linecap="round"/>
	</svg>""",

	"item_note": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="13" y="10" width="22" height="28" rx="2" stroke="{C1}" stroke-width="2.0" fill="{C2}" fill-opacity="0.14"/>
		<path d="M13 14.5 H35 M13 33.5 H35" stroke="{C1}" stroke-width="1.6"/>
		<path d="M17 21 H31 M17 26 H28" stroke="{C2}" stroke-width="1.7" stroke-linecap="round"/>
		<circle cx="34" cy="9" r="1.3" fill="{C2}"/>
	</svg>""",

	"equip_immortal_sword": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 5 L28.5 19 L24 43 L19.5 19 Z" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round" fill="{C2}" fill-opacity="0.28"/>
		<path d="M15 19 H33" stroke="{C1}" stroke-width="2.6" stroke-linecap="round"/>
		<path d="M24 24 V38" stroke="{C2}" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M20 45 H28" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
		<circle cx="24" cy="13" r="1.4" fill="{C2}"/>
	</svg>""",

	"equip_chaos_axe": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M13 41 L30 16" stroke="{C1}" stroke-width="3.0" stroke-linecap="round"/>
		<path d="M26 7 C34 9.5 39 16 38 25.5 C31.5 22 27.5 18 25.5 13.5 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.30"/>
		<path d="M30 14 C33 17.5 35 21.5 36 24.5" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M10 41 H18" stroke="{C2}" stroke-width="2.2" stroke-linecap="round"/>
	</svg>""",

	"equip_immortal_robe": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 9 L14 15 L11 39 H37 L34 15 Z" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round" fill="{C2}" fill-opacity="0.22"/>
		<path d="M17.5 15 C19.5 22.5 28.5 22.5 30.5 15" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M24 22 V39" stroke="{C2}" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M14 31 C18 34 30 34 34 31" stroke="{C2}" stroke-width="1.4" stroke-linecap="round"/>
	</svg>""",

	"item_high_ward": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<circle cx="24" cy="24" r="13" stroke="{C1}" stroke-width="2.1" fill="{C1}" fill-opacity="0.08"/>
		<circle cx="24" cy="24" r="5.5" stroke="{C2}" stroke-width="1.4" fill="{C2}" fill-opacity="0.22"/>
		<path d="M24 11 V18 M24 30 V37 M11 24 H18 M30 24 H37" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
		<path d="M16 16 L20 20 M32 16 L28 20 M16 32 L20 28 M32 32 L28 28" stroke="{C2}" stroke-width="1.2" stroke-linecap="round"/>
	</svg>""",

	"item_high_thunder": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<rect x="12" y="8" width="24" height="32" rx="2" stroke="{C1}" stroke-width="2.0" fill="{C1}" fill-opacity="0.10"/>
		<path d="M12 13 H36 M12 35 H36" stroke="{C1}" stroke-width="1.4"/>
		<path d="M26 14 L19 26 H24 L20.5 34 L30 21 H25 Z" stroke="{C2}" stroke-width="1.3" stroke-linejoin="round" fill="{C2}" fill-opacity="0.65"/>
		<circle cx="34" cy="7" r="1.3" fill="{C2}"/>
	</svg>""",

	"enemy_youming_abyss": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 6 C33 10 37 20 34 31 C32 38 28 41 24 41 C20 41 16 38 14 31 C11 20 15 10 24 6 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.20"/>
		<path d="M24 6 L20 2 M24 6 L28 2" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
		<circle cx="19.5" cy="20" r="2.2" fill="{C2}"/>
		<circle cx="28.5" cy="20" r="2.2" fill="{C2}"/>
		<path d="M19 31 C21.5 34 26.5 34 29 31" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M12 40 C16 37 20 40 24 37 C28 40 32 37 36 40" stroke="{C2}" stroke-width="1.3" stroke-linecap="round"/>
	</svg>""",

	"enemy_star_sea": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M8 28 C14 16 34 16 40 28 C34 24 28 24 24 27 C20 24 14 24 8 28 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.22"/>
		<path d="M24 27 V38" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
		<path d="M18 38 C21 35 27 35 30 38" stroke="{C2}" stroke-width="1.4" stroke-linecap="round"/>
		<path d="M32 10 L34 14 L38 16 L34 18 L32 22 L30 18 L26 16 L30 14 Z" stroke="{C2}" stroke-width="1.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.45"/>
		<circle cx="13" cy="14" r="1.3" fill="{C2}"/>
		<circle cx="19" cy="8" r="1.0" fill="{C2}"/>
	</svg>""",

	"enemy_chaos_realm": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M15 41 L12 26 L18 15 L30 12 L38 22 L36 36 L28 42 Z" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round" fill="{C2}" fill-opacity="0.20"/>
		<path d="M18 15 L22 24 L30 22 L34 30" stroke="{C1}" stroke-width="1.4" stroke-linecap="round"/>
		<circle cx="20" cy="27" r="2.0" fill="{C2}"/>
		<circle cx="31" cy="30" r="2.0" fill="{C2}"/>
		<path d="M22 36 L26 39" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M8 10 L12 12 M40 10 L36 13 M24 4 L24 8" stroke="{C2}" stroke-width="1.3" stroke-linecap="round"/>
	</svg>""",

	"enemy_heaven_beyond": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
		<path d="M24 8 L31 12 V22 C31 30 28 36 24 39 C20 36 17 30 17 22 V12 Z" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round" fill="{C2}" fill-opacity="0.20"/>
		<path d="M17 17 H31" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
		<path d="M24 12 V36" stroke="{C2}" stroke-width="1.3" stroke-linecap="round"/>
		<path d="M36 6 L41 8 M36 46 L41 44" stroke="{C2}" stroke-width="1.5" stroke-linecap="round"/>
		<path d="M38 8 V44" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
		<circle cx="24" cy="6" r="1.4" fill="{C2}"/>
	</svg>""",

	# ==================== 渡劫阵盘（UI 专用，200x200，不参与物品图鉴映射） ====================
	"tribulation_ring_outer": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
	  <circle cx="100" cy="100" r="91" fill="none" stroke="{C1}" stroke-width="1.6" stroke-opacity="0.48"/>
	  <circle cx="100" cy="100" r="86" fill="none" stroke="{C1}" stroke-width="1.0" stroke-opacity="0.32"/>
	  <circle cx="100" cy="100" r="64" fill="none" stroke="{C1}" stroke-width="1.4" stroke-opacity="0.45"/>
	  <polygon points="100,5.5 103.2,9 100,12.5 96.8,9" fill="{C2}" fill-opacity="0.85"/>
	  <polygon points="100,187.5 103.2,191 100,194.5 96.8,191" fill="{C2}" fill-opacity="0.85"/>
	  <polygon points="5.5,100 9,96.8 12.5,100 9,103.2" fill="{C2}" fill-opacity="0.85"/>
	  <polygon points="187.5,100 191,96.8 194.5,100 191,103.2" fill="{C2}" fill-opacity="0.85"/>
	  <g transform="translate(100,25) rotate(0)" stroke="{C2}" stroke-width="1.8" stroke-linecap="round">
	    <path d="M -7 -4.2 L 7 -4.2 M -7 0 L 7 0 M -7 4.2 L 7 4.2"/>
	  </g>
	  <g transform="translate(153.03,46.97) rotate(45)" stroke="{C2}" stroke-width="1.8" stroke-linecap="round">
	    <path d="M -7 -4.2 L -1.8 -4.2 M 1.8 -4.2 L 7 -4.2 M -7 0 L 7 0 M -7 4.2 L 7 4.2"/>
	  </g>
	  <g transform="translate(175,100) rotate(90)" stroke="{C2}" stroke-width="1.8" stroke-linecap="round">
	    <path d="M -7 -4.2 L 7 -4.2 M -7 0 L -1.8 0 M 1.8 0 L 7 0 M -7 4.2 L 7 4.2"/>
	  </g>
	  <g transform="translate(153.03,153.03) rotate(135)" stroke="{C2}" stroke-width="1.8" stroke-linecap="round">
	    <path d="M -7 -4.2 L -1.8 -4.2 M 1.8 -4.2 L 7 -4.2 M -7 0 L -1.8 0 M 1.8 0 L 7 0 M -7 4.2 L 7 4.2"/>
	  </g>
	  <g transform="translate(100,175) rotate(180)" stroke="{C2}" stroke-width="1.8" stroke-linecap="round">
	    <path d="M -7 -4.2 L -1.8 -4.2 M 1.8 -4.2 L 7 -4.2 M -7 0 L -1.8 0 M 1.8 0 L 7 0 M -7 4.2 L -1.8 4.2 M 1.8 4.2 L 7 4.2"/>
	  </g>
	  <g transform="translate(46.97,153.03) rotate(225)" stroke="{C2}" stroke-width="1.8" stroke-linecap="round">
	    <path d="M -7 -4.2 L 7 -4.2 M -7 0 L 7 0 M -7 4.2 L -1.8 4.2 M 1.8 4.2 L 7 4.2"/>
	  </g>
	  <g transform="translate(25,100) rotate(270)" stroke="{C2}" stroke-width="1.8" stroke-linecap="round">
	    <path d="M -7 -4.2 L -1.8 -4.2 M 1.8 -4.2 L 7 -4.2 M -7 0 L 7 0 M -7 4.2 L -1.8 4.2 M 1.8 4.2 L 7 4.2"/>
	  </g>
	  <g transform="translate(46.97,46.97) rotate(315)" stroke="{C2}" stroke-width="1.8" stroke-linecap="round">
	    <path d="M -7 -4.2 L 7 -4.2 M -7 0 L -1.8 0 M 1.8 0 L 7 0 M -7 4.2 L -1.8 4.2 M 1.8 4.2 L 7 4.2"/>
	  </g>
	</svg>""",

	"tribulation_ring_inner": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
	  <circle cx="100" cy="100" r="42" fill="none" stroke="{C1}" stroke-width="1.1" stroke-opacity="0.28" stroke-dasharray="3 5"/>
	  <path d="M 52.87 78.02 A 53.6 53.6 0 0 1 148.58 77.35 L 145.68 78.70 A 50.4 50.4 0 0 0 52.87 78.02 Z" fill="{C2}" fill-opacity="0.72"/>
	  <circle cx="147.13" cy="78.02" r="6.2" fill="{C2}" fill-opacity="0.20"/>
	  <circle cx="147.13" cy="78.02" r="2.8" fill="{C2}" fill-opacity="0.95"/>
	  <path d="M 147.13 121.98 A 53.6 53.6 0 0 1 51.42 122.65 L 54.32 121.30 A 50.4 50.4 0 0 0 147.13 121.98 Z" fill="{C2}" fill-opacity="0.72"/>
	  <circle cx="52.87" cy="121.98" r="6.2" fill="{C2}" fill-opacity="0.20"/>
	  <circle cx="52.87" cy="121.98" r="2.8" fill="{C2}" fill-opacity="0.95"/>
	</svg>""",

	# ==================== 仙坊阁法器精绘（5 枚，替代旧通用造型） ====================
	"gear_bell_charm": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="8.5" r="2.8" fill="none" stroke="{C1}" stroke-width="2.1"/>
	  <path d="M 18.5 13.5 C 17 19.5 15.5 26.5 11.5 32.2 Q 17.5 35 24 35 Q 30.5 35 36.5 32.2 C 32.5 26.5 31 19.5 29.5 13.5 Q 24 11.2 18.5 13.5 Z" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 17.6 17.8 Q 24 19.4 30.4 17.8" fill="none" stroke="{C1}" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.55"/>
	  <path d="M 13.6 29.2 Q 24 32 34.4 29.2" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <polygon points="24,20.5 27,24 24,27.5 21,24" fill="{C2}" fill-opacity="0.72" stroke="{C2}" stroke-width="1.2" stroke-linejoin="round"/>
	  <circle cx="24" cy="36.6" r="2.5" fill="{C2}" stroke="{C1}" stroke-width="1.8"/>
	  <path d="M 24 39.2 L 24 43 M 22.3 39.1 L 21.2 42.2 M 25.7 39.1 L 26.8 42.2" fill="none" stroke="{C2}" stroke-width="1.4" stroke-linecap="round"/>
	  <path d="M 8.8 19.5 Q 6.2 24.5 8.8 29.5 M 39.2 19.5 Q 41.8 24.5 39.2 29.5" fill="none" stroke="{C2}" stroke-width="1.7" stroke-linecap="round" stroke-opacity="0.85"/>
	  <path d="M 5.4 17 Q 2.6 24.5 5.4 32 M 42.6 17 Q 45.4 24.5 42.6 32" fill="none" stroke="{C2}" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.45"/>
	</svg>""",

	"gear_brush_zihao": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 36.8 8.4 L 39.6 11.2 L 23.6 27.6 L 20.4 24.4 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 22.6 22.2 L 25.8 25.4" fill="none" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
	  <path d="M 34.4 10.8 L 37.2 13.6" fill="none" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
	  <path d="M 39.2 9 Q 43 11 42.2 15.8" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	  <circle cx="42" cy="16.8" r="1.4" fill="{C2}"/>
	  <path d="M 20.4 24.4 C 15 26 12.2 31.5 10.5 37.5 C 16.5 35.8 22 33 23.6 27.6 Z" fill="{C2}" fill-opacity="0.45" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 16.5 31.5 L 12 36" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <path d="M 10.5 37.5 C 16 42.2 26 41.2 32 36.5 C 35.5 33.8 38.5 34.5 40.5 36.2" fill="none" stroke="{C2}" stroke-width="2.0" stroke-linecap="round" stroke-opacity="0.85"/>
	  <path d="M 13.5 10.5 L 14.4 13.1 L 17 14 L 14.4 14.9 L 13.5 17.5 L 12.6 14.9 L 10 14 L 12.6 13.1 Z" fill="{C2}" fill-opacity="0.85"/>
	</svg>""",

	"tool_hoe_biyu": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 8.8 37.4 L 29.8 16.4 L 32 18.6 L 11 39.6 Z" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <circle cx="9.6" cy="38.8" r="2.0" fill="{C2}" fill-opacity="0.45" stroke="{C1}" stroke-width="1.7"/>
	  <path d="M 14.5 32.5 L 16.5 34.5 M 18 29 L 20 31" fill="none" stroke="{C1}" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.6"/>
	  <path d="M 27.2 15.2 L 21.5 12.6 L 19 14 L 25.6 18.4 Z" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 30.8 15.6 C 35.5 18.2 39.5 22.8 40 29.5 L 34.2 32.6 C 32.5 27.2 29.8 23.2 26.8 20.6 Z" fill="{C2}" fill-opacity="0.34" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 37.6 22.8 C 38.4 25.8 37.5 28.4 34.8 30.2" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <polygon points="29,14.5 32.5,18 29,21.5 25.5,18" fill="{C1}" fill-opacity="0.28" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round"/>
	  <path d="M 38.5 9.5 L 39.3 11.7 L 41.5 12.5 L 39.3 13.3 L 38.5 15.5 L 37.7 13.3 L 35.5 12.5 L 37.7 11.7 Z" fill="{C2}" fill-opacity="0.88"/>
	  <path d="M 24.5 36.5 Q 24.5 31.5 28.5 30.5 Q 28 35 24.5 36.5 Z" fill="{C2}" fill-opacity="0.55" stroke="{C2}" stroke-width="1.2" stroke-linejoin="round"/>
	</svg>""",

	"tool_axe_hantie": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 9.4 37.2 L 32.8 10.6 L 35.2 12.8 L 11.8 39.4 Z" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <circle cx="10.2" cy="38.6" r="2.1" fill="{C2}" fill-opacity="0.45" stroke="{C1}" stroke-width="1.8"/>
	  <path d="M 15.2 31.6 L 17.4 33.6 M 18.2 28.2 L 20.4 30.2" fill="none" stroke="{C1}" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.6"/>
	  <path d="M 26.2 16.5 L 20.2 13.2 L 23.6 19.4 Z" fill="{C1}" fill-opacity="0.24" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 29.8 15.2 Q 33.2 14.8 35.6 13.4 C 41.8 20.4 40.6 28.4 31.6 34.4 Q 29.8 29.6 26.2 22.2 Z" fill="{C1}" fill-opacity="0.20" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 34.4 15.2 C 39.4 21 38.4 27.6 31.8 32.6" fill="none" stroke="{C2}" stroke-width="2.2" stroke-linecap="round"/>
	  <polygon points="31.5,20.5 33.8,22.8 31.5,25.1 29.2,22.8" fill="{C2}" fill-opacity="0.78"/>
	  <path d="M 41 10 L 41 14 M 39 12 L 43 12" fill="none" stroke="{C2}" stroke-width="1.5" stroke-linecap="round" stroke-opacity="0.85"/>
	</svg>""",

	"tool_pick_xuanjin": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 8.8 37.8 L 31.4 15.2 L 33.8 17.6 L 11.2 40.2 Z" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <polygon points="34.2,14.8 31.4,15.2 33.8,17.6" fill="{C2}" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round"/>
	  <circle cx="9.6" cy="39.4" r="2.0" fill="{C2}" fill-opacity="0.45" stroke="{C1}" stroke-width="1.8"/>
	  <path d="M 12.8 12.2 Q 25.2 12.4 31.4 18.6 Q 36.6 24.8 36.8 36.2 Q 32.4 27.8 27.4 22.6 Q 22.2 17.6 12.8 12.2 Z" fill="{C1}" fill-opacity="0.20" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 16.5 13.6 Q 22.2 14.8 26.2 18 M 30.8 22.8 Q 34.2 26.8 35.4 32.5" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <polygon points="29,17.2 31.8,20 29,22.8 26.2,20" fill="{C2}" fill-opacity="0.88" stroke="{C1}" stroke-width="1.5" stroke-linejoin="round"/>
	  <path d="M 41 31.5 L 41.8 33.7 L 44 34.5 L 41.8 35.3 L 41 37.5 L 40.2 35.3 L 38 34.5 L 40.2 33.7 Z" fill="{C2}" fill-opacity="0.9"/>
	</svg>""",

	# ==================== 仙坊阁入门法器精绘（6 枚，与高阶同系拆分独立造型） ====================
	"tool_axe_xuantie": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 8.7 36.9 L 31.7 10.9 L 34.3 13.1 L 11.3 39.1 Z" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 13.8 31.8 L 16.4 34.1 M 16.8 28.4 L 19.4 30.7" fill="none" stroke="{C1}" stroke-width="1.5" stroke-linecap="round" stroke-opacity="0.65"/>
	  <path d="M 22.5 14.5 Q 28.8 14.4 34.5 14 C 40 19.5 39.5 26.5 32.5 32.5 Q 28.5 26.5 24.5 22.5 L 21.2 18.5 Z" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 33.8 16.2 C 37.6 20.6 37.2 25.8 31.8 30.6" fill="none" stroke="{C2}" stroke-width="2.1" stroke-linecap="round"/>
	  <path d="M 24.8 16.2 L 28.8 20.2" fill="none" stroke="{C1}" stroke-width="1.6" stroke-linecap="round" stroke-opacity="0.7"/>
	  <circle cx="29.8" cy="21.8" r="1.4" fill="{C2}"/>
	</svg>""",

	"tool_hoe_qingtong": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 8.8 37 L 29 14 L 31.4 16 L 11.2 39 Z" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 13.8 32 L 16.1 34 M 16.8 28.6 L 19.1 30.6" fill="none" stroke="{C1}" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.6"/>
	  <path d="M 27.2 15.2 L 24 12.6 L 22.4 14.4 L 25.6 17 Z" fill="{C1}" fill-opacity="0.24" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 30.8 14.8 L 39.5 23.2 Q 37.8 26.8 34.5 29.5 L 27.2 20.5 Z" fill="{C2}" fill-opacity="0.26" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 37.8 23.6 Q 36.4 26.2 34.4 28" fill="none" stroke="{C2}" stroke-width="1.9" stroke-linecap="round"/>
	  <path d="M 29.8 18.2 L 35.8 24.2" fill="none" stroke="{C1}" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.6"/>
	  <polygon points="29.2,13.5 32.5,16.5 29.4,19.8 26.2,16.8" fill="{C1}" fill-opacity="0.28" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round"/>
	  <path d="M 24.8 40 Q 25 36.5 26 34.2" fill="none" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
	  <path d="M 25 36.8 Q 20.8 35.8 19.8 32.8 Q 23.2 32.2 25 36.8 Z" fill="{C2}" fill-opacity="0.55" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round"/>
	  <path d="M 25.4 35.8 Q 29.2 34.4 30.6 31.6 Q 27.2 31.4 25.4 35.8 Z" fill="{C2}" fill-opacity="0.45" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round"/>
	</svg>""",

	"tool_pick_poyan": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 8.5 37.3 L 29.5 15.3 L 31.9 17.6 L 10.9 39.6 Z" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 14.5 12.2 Q 24.5 11.2 31.8 17.5 Q 37.5 22.8 39 33.2 Q 33.8 25.8 28.5 21.5 Q 22.5 16.8 13.8 15.6 Z" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 31.2 19.2 Q 35.2 23.2 37.4 29.2 M 15 13.8 L 19.2 14.3" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <polygon points="28.2,14.2 31.8,17.6 28.6,21.2 25.0,17.8" fill="{C2}" fill-opacity="0.45" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round"/>
	  <polygon points="21,39.5 23.8,33.5 29.5,32.5 33.2,36 32,39.5" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 27.2 33.2 L 26.2 36.2 L 28.6 38.6" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	"gear_furnace_qingtong": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="9.2" r="2.3" fill="{C2}" fill-opacity="0.85" stroke="{C1}" stroke-width="1.7"/>
	  <path d="M 15.2 17.2 Q 16.8 12.2 24 12.2 Q 31.2 12.2 32.8 17.2 Z" fill="{C2}" fill-opacity="0.20" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 13.5 17.5 L 34.5 17.5" fill="none" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
	  <path d="M 14.2 19.5 C 12 27.5 15.5 34.5 24 34.5 C 32.5 34.5 36 27.5 33.8 19.5 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 13.8 20.6 C 8.8 20.6 8.8 26.8 13.8 27.2 M 34.2 20.6 C 39.2 20.6 39.2 26.8 34.2 27.2" fill="none" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
	  <path d="M 14.6 23.2 Q 24 25.2 33.4 23.2" fill="none" stroke="{C1}" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.58"/>
	  <path d="M 24 25.8 Q 27 28.8 24 31.6 Q 21 28.8 24 25.8 Z" fill="{C2}" fill-opacity="0.82" stroke="{C2}" stroke-width="1.2" stroke-linejoin="round"/>
	  <path d="M 16.8 33.2 Q 15.2 37.5 13.8 41.2 M 24 34.5 L 24 41.5 M 31.2 33.2 Q 32.8 37.5 34.2 41.2" fill="none" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
	  <path d="M 11.8 14.2 Q 9.5 10.8 12.2 7.6 M 36.2 14.2 Q 38.5 10.8 35.8 7.6" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round" stroke-opacity="0.78"/>
	</svg>""",

	"gear_hammer_dihuo": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 8.2 37.2 L 26.5 18.9 L 29.3 21.7 L 11 40 Z" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <circle cx="9.5" cy="38.6" r="2.1" fill="{C2}" fill-opacity="0.45" stroke="{C1}" stroke-width="1.8"/>
	  <path d="M 14.2 32 L 16.8 34.6 M 17.5 28.7 L 20.1 31.3" fill="none" stroke="{C1}" stroke-width="1.5" stroke-linecap="round" stroke-opacity="0.65"/>
	  <polygon points="27.5,7.8 40.2,20.5 40.1,23.4 34.4,29.1 31.5,29.2 18.8,16.5 18.9,13.6 24.6,7.9" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 28.9 9.2 L 20.2 17.9 M 38.8 19.1 L 30.1 27.8" fill="none" stroke="{C1}" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.58"/>
	  <polygon points="29.5,14.8 33.2,18.5 29.5,22.2 25.8,18.5" fill="{C2}" fill-opacity="0.82" stroke="{C2}" stroke-width="1.2" stroke-linejoin="round"/>
	  <path d="M 38.5 9.2 L 38.5 13.8 M 36.2 11.5 L 40.8 11.5" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	  <circle cx="40.8" cy="30.2" r="1.5" fill="{C2}" fill-opacity="0.88"/>
	  <circle cx="37.2" cy="33.5" r="1.2" fill="{C2}" fill-opacity="0.65"/>
	</svg>""",

	"gear_mat_juling": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 7.5 29 L 7.5 33.5 C 7.5 38.2 14.9 41.2 24 41.2 C 33.1 41.2 40.5 38.2 40.5 33.5 L 40.5 29" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <ellipse cx="24" cy="29" rx="16.5" ry="6.2" fill="{C1}" fill-opacity="0.10" stroke="{C1}" stroke-width="2.2"/>
	  <ellipse cx="24" cy="29" rx="10.2" ry="3.4" fill="{C2}" fill-opacity="0.18" stroke="{C2}" stroke-width="1.5"/>
	  <polygon points="24,26.9 27.6,29 24,31.1 20.4,29" fill="{C2}" fill-opacity="0.85"/>
	  <path d="M 13 34.4 L 13 38.4 M 18.5 35.8 L 18.5 39.8 M 24 36.2 L 24 40.4 M 29.5 35.8 L 29.5 39.8 M 35 34.4 L 35 38.4" fill="none" stroke="{C1}" stroke-width="1.3" stroke-linecap="round" stroke-opacity="0.52"/>
	  <path d="M 11.5 22.5 C 9.5 16.5 13.5 11.5 19.5 10.2 M 36.5 22.5 C 38.5 16.5 34.5 11.5 28.5 10.2" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round" stroke-opacity="0.85"/>
	  <path d="M 16.8 23.5 Q 16.5 17.5 20.8 15.2 M 31.2 23.5 Q 31.5 17.5 27.2 15.2" fill="none" stroke="{C2}" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.6"/>
	  <path d="M 24 6.2 L 25.1 9.4 L 28.3 10.5 L 25.1 11.6 L 24 14.8 L 22.9 11.6 L 19.7 10.5 L 22.9 9.4 Z" fill="{C2}" fill-opacity="0.92"/>
	  <circle cx="15.2" cy="13.5" r="1.2" fill="{C2}" fill-opacity="0.75"/>
	  <circle cx="32.8" cy="13.5" r="1.2" fill="{C2}" fill-opacity="0.75"/>
	</svg>""",

	# ==================== 九幽冥渊（化神） ====================
	"enemy_youming_ghost": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 10 38 L 38 10 M 38 38 L 10 10" fill="none" stroke="{C1}" stroke-width="2.0" stroke-linecap="round" stroke-opacity="0.55"/>
	  <polygon points="8,8 14,9.5 9.5,14" fill="{C2}" fill-opacity="0.7" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round"/>
	  <polygon points="40,8 34,9.5 38.5,14" fill="{C2}" fill-opacity="0.7" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round"/>
	  <path d="M 14.5 22 C 14.5 13.5 33.5 13.5 33.5 22 L 35.5 35.5 L 24 41 L 12.5 35.5 Z" fill="{C1}" fill-opacity="0.24" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 15 17.5 Q 9 14.5 8 8.5 M 33 17.5 Q 39 14.5 40 8.5" fill="none" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
	  <path d="M 17.5 23 L 22 25 M 30.5 23 L 26 25" fill="none" stroke="{C2}" stroke-width="2.3" stroke-linecap="round"/>
	  <path d="M 18.5 32 L 29.5 32 M 21 30 L 21 35 M 24 30 L 24 36 M 27 30 L 27 35" fill="none" stroke="{C1}" stroke-width="1.5" stroke-linecap="round"/>
	</svg>""",

	"enemy_blood_crow": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 24 17.5 C 18 11 9.5 10.5 4.5 14.5 L 11 19.5 L 6.5 23 L 14 25.5 L 10.5 29.5 L 19.5 29 L 18 40 L 24 36.5 L 30 40 L 28.5 29 L 37.5 29.5 L 34 25.5 L 41.5 23 L 37 19.5 L 43.5 14.5 C 38.5 10.5 30 11 24 17.5 Z" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 21 15.5 C 21 10.5 28 10.5 28 15.5 L 26.5 21 L 22.5 21 Z" fill="{C1}" fill-opacity="0.28" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
	  <path d="M 21 13.5 L 15.5 14.5 L 20.5 17" fill="{C2}" fill-opacity="0.6" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round"/>
	  <circle cx="24.2" cy="14" r="1.5" fill="{C2}"/>
	  <path d="M 8 15.5 L 14.5 19.5 M 40 15.5 L 33.5 19.5 M 13 24 L 18 25.5 M 35 24 L 30 25.5" fill="none" stroke="{C2}" stroke-width="1.7" stroke-linecap="round"/>
	</svg>""",

	"enemy_jiuyou_king": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="23.5" r="19.5" fill="none" stroke="{C2}" stroke-width="1.5" stroke-opacity="0.52" stroke-dasharray="10 4"/>
	  <path d="M 9 17 Q 6 11.5 10.5 7.5 Q 11 12.5 14 14 M 39 17 Q 42 11.5 37.5 7.5 Q 37 12.5 34 14" fill="{C2}" fill-opacity="0.35" stroke="{C2}" stroke-width="1.6" stroke-linejoin="round"/>
	  <path d="M 15 16.5 L 13 7.5 L 19.5 11.5 L 24 3.8 L 28.5 11.5 L 35 7.5 L 33 16.5 Z" fill="{C1}" fill-opacity="0.28" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <polygon points="24,8.2 26.2,11.2 24,14.2 21.8,11.2" fill="{C2}"/>
	  <path d="M 16.5 17 L 31.5 17 L 30 29 L 24 33 L 18 29 Z" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 18.8 21.8 L 22.8 23.4 M 29.2 21.8 L 25.2 23.4" fill="none" stroke="{C2}" stroke-width="2.3" stroke-linecap="round"/>
	  <path d="M 20.5 28 L 22.2 26.2 L 24 28.2 L 25.8 26.2 L 27.5 28" fill="none" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round"/>
	  <path d="M 6.5 42.5 L 9.5 29 L 17.5 31 L 24 34.5 L 30.5 31 L 38.5 29 L 41.5 42.5 Z" fill="{C1}" fill-opacity="0.24" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 14.5 17 L 13.5 25 M 33.5 17 L 34.5 25 M 24 35.5 L 24 41" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	# ==================== 无尽星海（炼虚） ====================
	"enemy_star_whale": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 7.5 27.5 C 8 15 21 10 31.5 16.5 C 35.5 19 37.5 23.5 39 27.5 L 43.5 21.5 L 42.5 29 L 44 33.5 L 37.5 31.5 C 32 34 21 34 12.5 32 C 9 31.2 7.2 29.5 7.5 27.5 Z" fill="{C1}" fill-opacity="0.20" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 22 30.5 Q 17.5 36.5 13 39 Q 19.5 38 25.5 32.5" fill="{C1}" fill-opacity="0.24" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
	  <circle cx="13.5" cy="26.5" r="1.4" fill="{C2}"/>
	  <path d="M 18 20.5 L 23.5 17.5 L 29 21 L 34 19.5" fill="none" stroke="{C2}" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
	  <circle cx="18" cy="20.5" r="1.4" fill="{C2}"/>
	  <circle cx="23.5" cy="17.5" r="1.7" fill="{C2}"/>
	  <circle cx="29" cy="21" r="1.4" fill="{C2}"/>
	  <path d="M 10 39.5 Q 24 43 38 39" fill="none" stroke="{C2}" stroke-width="1.5" stroke-linecap="round" stroke-opacity="0.65"/>
	</svg>""",

	"enemy_nebula_spirit": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 18.5 11.5 A 6.5 6.5 0 1 0 29.5 11.5 A 5.2 5.2 0 1 1 18.5 11.5 Z" fill="{C2}" fill-opacity="0.75" stroke="{C1}" stroke-width="1.6"/>
	  <path d="M 24 18.5 C 14.5 18.5 10.5 26 15 32 C 18.5 36.5 14 40 12 41.5 C 21 42.5 31.5 39 34 32 C 37 24.5 32.5 18.5 24 18.5 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 12 24.5 C 17 21 31 21 36 27.5 C 32 34.5 18 35.5 13 30.5" fill="none" stroke="{C2}" stroke-width="1.7" stroke-linecap="round" stroke-opacity="0.8"/>
	  <path d="M 24 22.5 L 25.3 26.2 L 29 27.5 L 25.3 28.8 L 24 32.5 L 22.7 28.8 L 19 27.5 L 22.7 26.2 Z" fill="{C2}"/>
	  <circle cx="9.5" cy="17.5" r="1.5" fill="{C2}"/>
	  <circle cx="39" cy="18.5" r="1.4" fill="{C2}" fill-opacity="0.75"/>
	</svg>""",

	"enemy_void_dragon": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <ellipse cx="24" cy="24" rx="20.5" ry="9.5" transform="rotate(-28 24 24)" fill="none" stroke="{C2}" stroke-width="1.5" stroke-opacity="0.65"/>
	  <ellipse cx="24" cy="24" rx="20.5" ry="9.5" transform="rotate(28 24 24)" fill="none" stroke="{C1}" stroke-width="1.4" stroke-opacity="0.45"/>
	  <circle cx="24" cy="24.5" r="6.2" fill="{C1}" fill-opacity="0.34" stroke="{C2}" stroke-width="1.9"/>
	  <circle cx="24" cy="24.5" r="2.6" fill="{C2}" fill-opacity="0.85"/>
	  <path d="M 27 12.5 C 16.5 9.5 9.5 16.5 10.5 26 C 11.5 35.5 21 41.5 31.5 38.5 C 36.5 37 39.5 32.5 40 28" fill="none" stroke="{C1}" stroke-width="5.2" stroke-linecap="round" stroke-opacity="0.22"/>
	  <path d="M 27 12.5 C 16.5 9.5 9.5 16.5 10.5 26 C 11.5 35.5 21 41.5 31.5 38.5 C 36.5 37 39.5 32.5 40 28" fill="none" stroke="{C1}" stroke-width="2.2" stroke-linecap="round"/>
	  <polygon points="25.5,9.5 35.5,11 33.5,16.5 25.5,15.5" fill="{C1}" fill-opacity="0.28" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
	  <path d="M 27 9.8 L 22.5 4.5 M 31 10 L 34 4.8" fill="none" stroke="{C1}" stroke-width="1.9" stroke-linecap="round"/>
	  <circle cx="31.5" cy="13" r="1.5" fill="{C2}"/>
	  <path d="M 10.5 11 L 11.4 13.4 L 13.8 14.3 L 11.4 15.2 L 10.5 17.6 L 9.6 15.2 L 7.2 14.3 L 9.6 13.4 Z" fill="{C2}"/>
	  <path d="M 38.5 34.5 L 39.3 36.7 L 41.5 37.5 L 39.3 38.3 L 38.5 40.5 L 37.7 38.3 L 35.5 37.5 L 37.7 36.7 Z" fill="{C2}"/>
	</svg>""",

	# ==================== 混沌古界（合体） ====================
	"enemy_chaos_golem": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <polygon points="12.5,37.5 9.5,20.5 17,10.5 24,14.5 31,9.5 38.5,21 35.5,37.5 24,41.5" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 16.5 23.5 Q 24 18 31.5 23.5 Q 24 29 16.5 23.5 Z" fill="{C2}" fill-opacity="0.28" stroke="{C2}" stroke-width="1.8" stroke-linejoin="round"/>
	  <circle cx="24" cy="23.5" r="2.3" fill="{C2}"/>
	  <path d="M 24 29 L 21.5 34 L 24.5 39.5 M 13 28.5 L 17.5 30.5 M 35 28 L 30.5 30.5" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
	  <polygon points="5.5,14 9,12.5 8.5,16.5" fill="{C1}" fill-opacity="0.3" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round"/>
	  <polygon points="41.5,14.5 38.5,13 39,17" fill="{C1}" fill-opacity="0.3" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round"/>
	</svg>""",

	"enemy_void_devourer": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 29 12 C 36 8.5 42 12 42 19 C 42 25 38 29 34 31" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
	  <circle cx="22.5" cy="25.5" r="14.5" fill="{C1}" fill-opacity="0.20" stroke="{C1}" stroke-width="2.2"/>
	  <circle cx="22.5" cy="25.5" r="9.2" fill="{C1}" fill-opacity="0.30" stroke="{C1}" stroke-width="1.8"/>
	  <path d="M 22.5 11.2 L 22.5 17.5 M 22.5 39.8 L 22.5 33.5 M 8.2 25.5 L 14.5 25.5 M 36.8 25.5 L 30.5 25.5 M 12.5 15.5 L 17 20 M 32.5 35.5 L 28 31 M 32.5 15.5 L 28 20 M 12.5 35.5 L 17 31" fill="none" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
	  <path d="M 22.5 20.5 A 5 5 0 1 1 18 27.5 A 3 3 0 1 1 24.5 25.5" fill="none" stroke="{C2}" stroke-width="1.9" stroke-linecap="round"/>
	  <circle cx="22.5" cy="25.5" r="1.8" fill="{C2}"/>
	</svg>""",

	"enemy_chaos_lord": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="24" r="19.8" fill="none" stroke="{C1}" stroke-width="1.5" stroke-opacity="0.42" stroke-dasharray="11 5"/>
	  <path d="M 14 14 Q 6.5 11 4.5 5.5 M 11.5 24 Q 5.5 24 3.5 20 M 14 34 Q 7 37 5.5 42.5 M 34 14 Q 41.5 11 43.5 5.5 M 36.5 24 Q 42.5 24 44.5 20 M 34 34 Q 41 37 42.5 42.5" fill="none" stroke="{C1}" stroke-width="2.1" stroke-linecap="round"/>
	  <polygon points="24,6.5 32.5,16 30.5,33.5 24,41 17.5,33.5 15.5,16" fill="{C1}" fill-opacity="0.24" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 24 12.5 Q 27 16.5 24 20.5 Q 21 16.5 24 12.5 Z" fill="{C2}" fill-opacity="0.85" stroke="{C1}" stroke-width="1.3"/>
	  <path d="M 18 24.5 Q 20.5 22.5 23 24.5 Q 20.5 26.5 18 24.5 Z M 25 24.5 Q 27.5 22.5 30 24.5 Q 27.5 26.5 25 24.5 Z" fill="{C2}"/>
	  <circle cx="24" cy="33" r="3.2" fill="{C2}" fill-opacity="0.35" stroke="{C2}" stroke-width="1.7"/>
	  <circle cx="24" cy="33" r="1.2" fill="{C2}"/>
	  <path d="M 24 2 L 24 5.5 M 24 42.5 L 24 46" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	# ==================== 三十三天外（大乘） ====================
	"enemy_heaven_general": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 38.5 7 L 38.5 41" fill="none" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
	  <polygon points="38.5,4.5 41.5,11.5 38.5,14 35.5,11.5" fill="{C2}" fill-opacity="0.72" stroke="{C1}" stroke-width="1.5" stroke-linejoin="round"/>
	  <path d="M 19 14.5 Q 11 10.5 9.5 5.5 M 25 14.5 Q 32 10.5 33 5.5" fill="none" stroke="{C2}" stroke-width="1.9" stroke-linecap="round"/>
	  <path d="M 14.5 21 C 14.5 14 29.5 14 29.5 21 L 28.5 29.5 L 22 33 L 15.5 29.5 Z" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 17.5 23 L 26.5 23" fill="none" stroke="{C2}" stroke-width="2.2" stroke-linecap="round"/>
	  <path d="M 10 41 L 12 32.5 L 22 34.5 L 32 32.5 L 34 41 Z" fill="{C1}" fill-opacity="0.24" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 8 28 C 6 22 10 18.5 14 20.5" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	"enemy_primordial_beast": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 16 16 C 8 11 4.5 16 7 22.5 C 8.8 27 13 26.5 14 23 M 32 16 C 40 11 43.5 16 41 22.5 C 39.2 27 35 26.5 34 23" fill="none" stroke="{C1}" stroke-width="2.5" stroke-linecap="round"/>
	  <path d="M 14.5 17.5 L 24 12 L 33.5 17.5 L 35.5 29.5 L 29.5 37.5 L 24 35 L 18.5 37.5 L 12.5 29.5 Z" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <polygon points="24,14.8 26.6,18 24,21.2 21.4,18" fill="{C2}" fill-opacity="0.88"/>
	  <path d="M 16.5 23.2 L 21.5 25 M 31.5 23.2 L 26.5 25" fill="none" stroke="{C2}" stroke-width="2.3" stroke-linecap="round"/>
	  <path d="M 16.5 36.5 L 18.2 30 L 21.2 35 M 31.5 36.5 L 29.8 30 L 26.8 35" fill="{C2}" fill-opacity="0.45" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round"/>
	</svg>""",

	"enemy_heaven_emperor": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="22" r="20.2" fill="none" stroke="{C2}" stroke-width="1.5" stroke-opacity="0.62"/>
	  <circle cx="24" cy="22" r="16.5" fill="none" stroke="{C1}" stroke-width="1.1" stroke-opacity="0.32" stroke-dasharray="6 4"/>
	  <path d="M 24 1.5 L 24 4.5 M 35 5 L 33.2 7.5 M 42.5 14 L 39.5 15.2 M 44.2 22 L 41.2 22 M 13 5 L 14.8 7.5 M 5.5 14 L 8.5 15.2 M 3.8 22 L 6.8 22" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <polygon points="10.5,11.5 37.5,11.5 35.5,15.5 12.5,15.5" fill="{C1}" fill-opacity="0.28" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
	  <polygon points="24,5.2 26.8,11.5 21.2,11.5" fill="{C2}" fill-opacity="0.88" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round"/>
	  <path d="M 15 15.5 L 15 20.5 M 19.5 15.5 L 19.5 21.2 M 28.5 15.5 L 28.5 21.2 M 33 15.5 L 33 20.5" fill="none" stroke="{C2}" stroke-width="1.5" stroke-linecap="round"/>
	  <path d="M 17 16 L 31 16 L 30 27.5 L 24 31.2 L 18 27.5 Z" fill="{C1}" fill-opacity="0.20" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
	  <polygon points="24,17.2 25.6,19.8 24,22.4 22.4,19.8" fill="{C2}"/>
	  <path d="M 19.5 24 L 22.5 24 M 25.5 24 L 28.5 24" fill="none" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
	  <path d="M 6.5 43.5 L 9.5 32.5 L 17.5 29.5 L 24 33 L 30.5 29.5 L 38.5 32.5 L 41.5 43.5 Z" fill="{C1}" fill-opacity="0.24" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <polygon points="24,35 27.5,38.5 24,42 20.5,38.5" fill="{C2}" fill-opacity="0.85" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round"/>
	  <path d="M 8 27.5 C 5 29.5 5 34.5 8 36.5 M 40 27.5 C 43 29.5 43 34.5 40 36.5" fill="none" stroke="{C2}" stroke-width="1.7" stroke-linecap="round"/>
	</svg>""",

	# ==================== 高阶灵药（5 枚，替代共用草苗造型） ====================
	"item_biyu_shen": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 21 20 Q 17 24 18 30 Q 15 35 13.5 40.5 Q 17.8 39.2 21.6 34.8 Q 24 33.8 26.4 34.8 Q 30.2 39.2 34.5 40.5 Q 33 35 30 30 Q 31 24 27 20 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 20 25 Q 24 26.6 28 25 M 19.6 29.5 Q 24 31.1 28.4 29.5" fill="none" stroke="{C1}" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.58"/>
	  <path d="M 17.2 30.8 Q 11.8 32.2 9.5 35.5 M 30.8 30.8 Q 36.2 32.2 38.5 35.5 M 24 34.6 Q 24 39.2 22.2 42.5" fill="none" stroke="{C1}" stroke-width="1.5" stroke-linecap="round" stroke-opacity="0.72"/>
	  <path d="M 24 20 L 24 11.5" fill="none" stroke="{C1}" stroke-width="2.1" stroke-linecap="round"/>
	  <path d="M 23.5 16.8 Q 15.2 16.8 11.5 12 Q 17 10.2 23.5 16.8 Z" fill="{C2}" fill-opacity="0.34" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 24.5 16.8 Q 32.8 16.8 36.5 12 Q 31 10.2 24.5 16.8 Z" fill="{C2}" fill-opacity="0.34" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <circle cx="24" cy="8.2" r="2.2" fill="{C2}" stroke="{C1}" stroke-width="1.4"/>
	  <circle cx="20.2" cy="10.4" r="1.6" fill="{C2}"/>
	  <circle cx="27.8" cy="10.4" r="1.6" fill="{C2}"/>
	  <path d="M 38 17.5 L 38 22.5 M 35.5 20 L 40.5 20" fill="none" stroke="{C2}" stroke-width="1.5" stroke-linecap="round" stroke-opacity="0.85"/>
	</svg>""",

	"item_longxue": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 15.5 40.5 Q 24 37.8 32.5 40.5" fill="none" stroke="{C1}" stroke-width="2.1" stroke-linecap="round"/>
	  <path d="M 22.8 39 C 14 35.2 8.5 26 9.5 15 C 13.8 19.2 17.4 25 22 33.2 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 25.2 39 C 34 35.2 39.5 26 38.5 15 C 34.2 19.2 30.6 25 26 33.2 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 24 39 C 18.2 30 19.2 18.8 24 7.5 C 28.8 18.8 29.8 30 24 39 Z" fill="{C2}" fill-opacity="0.26" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 24 36.8 L 24 14.5 M 20 34.5 Q 14.5 28 12.2 20.5 M 28 34.5 Q 33.5 28 35.8 20.5" fill="none" stroke="{C2}" stroke-width="1.5" stroke-linecap="round"/>
	  <path d="M 24 20.2 Q 27.6 25.2 24 28.8 Q 20.4 25.2 24 20.2 Z" fill="{C2}" fill-opacity="0.92" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round"/>
	  <path d="M 13.2 8.5 Q 15 11.4 13.2 13 Q 11.4 11.4 13.2 8.5 Z" fill="{C2}" fill-opacity="0.82"/>
	  <circle cx="35.8" cy="10.2" r="1.5" fill="{C2}" fill-opacity="0.85"/>
	  <circle cx="39.5" cy="27.5" r="1.2" fill="{C2}" fill-opacity="0.65"/>
	</svg>""",

	"item_taiyi_lian": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 22 33.2 C 11 33.2 6.2 26 8.5 19.2 C 14.5 20.2 19.5 25 22 33.2 Z" fill="{C1}" fill-opacity="0.14" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
	  <path d="M 26 33.2 C 37 33.2 41.8 26 39.5 19.2 C 33.5 20.2 28.5 25 26 33.2 Z" fill="{C1}" fill-opacity="0.14" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
	  <path d="M 23 33.2 C 14.5 28.5 12 19.5 15.5 13 C 20.5 16.5 23 23 23 33.2 Z" fill="{C2}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 25 33.2 C 33.5 28.5 36 19.5 32.5 13 C 27.5 16.5 25 23 25 33.2 Z" fill="{C2}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 24 33.2 C 17.8 25.5 18.5 15.5 24 9.2 C 29.5 15.5 30.2 25.5 24 33.2 Z" fill="{C2}" fill-opacity="0.34" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <polygon points="24,18.5 26.8,23.2 24,27.8 21.2,23.2" fill="{C2}" fill-opacity="0.88"/>
	  <path d="M 8.5 37.5 Q 16.2 40.2 24 37.5 Q 31.8 34.8 39.5 37.5" fill="none" stroke="{C2}" stroke-width="1.9" stroke-linecap="round"/>
	  <path d="M 14.5 41.4 Q 24 43.4 33.5 41.4" fill="none" stroke="{C1}" stroke-width="1.5" stroke-linecap="round" stroke-opacity="0.58"/>
	  <path d="M 38.5 7.5 L 39.3 10 L 41.8 10.8 L 39.3 11.6 L 38.5 14.1 L 37.7 11.6 L 35.2 10.8 L 37.7 10 Z" fill="{C2}" fill-opacity="0.9"/>
	  <circle cx="10.2" cy="11.8" r="1.5" fill="{C2}" fill-opacity="0.75"/>
	</svg>""",

	"item_hundun_flower": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="21" r="16.8" fill="none" stroke="{C2}" stroke-width="1.4" stroke-opacity="0.5" stroke-dasharray="10 6"/>
	  <path d="M 24 35 L 24 42.5" fill="none" stroke="{C1}" stroke-width="2.1" stroke-linecap="round"/>
	  <path d="M 23.5 39.8 Q 17 39.8 14.5 36.2 Q 19.2 35.6 23.5 39.8 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="1.7" stroke-linejoin="round"/>
	  <path d="M 24.5 39.8 Q 31 39.8 33.5 36.2 Q 28.8 35.6 24.5 39.8 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="1.7" stroke-linejoin="round"/>
	  <path d="M 24 14.8 C 20 11.8 20.5 8.2 24 6 C 27.5 8.2 28 11.8 24 14.8 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 24 27.2 C 20 30.2 20.5 33.8 24 36 C 27.5 33.8 28 30.2 24 27.2 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 29.4 17.8 C 31 13.8 33.8 12.6 37 13.5 C 36.2 16.6 33.8 19.2 29.4 17.8 Z" fill="{C2}" fill-opacity="0.24" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 29.4 24.2 C 33.8 22.8 36.2 25.4 37 28.5 C 33.8 29.4 31 28.2 29.4 24.2 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 18.6 17.8 C 14.2 19.2 11.8 16.6 11 13.5 C 14.2 12.6 17 13.8 18.6 17.8 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 18.6 24.2 C 17 28.2 14.2 29.4 11 28.5 C 11.8 25.4 14.2 22.8 18.6 24.2 Z" fill="{C2}" fill-opacity="0.24" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <circle cx="24" cy="21" r="6.2" fill="{C2}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.0"/>
	  <path d="M 24 14.8 A 3.1 3.1 0 0 1 24 21 A 3.1 3.1 0 0 0 24 27.2" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <circle cx="24" cy="17.9" r="1.2" fill="{C2}"/>
	  <circle cx="24" cy="24.1" r="1.2" fill="{C1}"/>
	</svg>""",

	"item_hongmeng_herb": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="20" r="17.8" fill="none" stroke="{C2}" stroke-width="1.5" stroke-opacity="0.58"/>
	  <circle cx="24" cy="20" r="14.2" fill="none" stroke="{C1}" stroke-width="1.0" stroke-opacity="0.28" stroke-dasharray="5 4"/>
	  <path d="M 24 35.5 C 21 38.5 17 40 13.5 41.5 M 24 35.5 C 27 38.5 31 40 34.5 41.5 M 24 35.5 L 24 42.5" fill="none" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
	  <path d="M 24 35.5 C 22.2 30.2 25.8 26.2 24 20.5" fill="none" stroke="{C1}" stroke-width="2.4" stroke-linecap="round"/>
	  <path d="M 23.4 31.5 C 15.2 32.5 9.8 28 8.2 22.2 C 14.2 22.6 19.4 25.8 23.4 31.5 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
	  <path d="M 24.6 31.5 C 32.8 32.5 38.2 28 39.8 22.2 C 33.8 22.6 28.6 25.8 24.6 31.5 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
	  <path d="M 23.4 24 C 15.8 21.6 12.2 16.5 13.2 11.2 C 17.8 13.6 21.4 17.8 23.4 24 Z" fill="{C2}" fill-opacity="0.30" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 24.6 24 C 32.2 21.6 35.8 16.5 34.8 11.2 C 30.2 13.6 26.6 17.8 24.6 24 Z" fill="{C2}" fill-opacity="0.30" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 24 6.8 C 29.4 11.5 29.8 18.2 24 21.2 C 18.2 18.2 18.6 11.5 24 6.8 Z" fill="{C2}" fill-opacity="0.62" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 24 11.4 L 24.9 14 L 27.5 14.9 L 24.9 15.8 L 24 18.4 L 23.1 15.8 L 20.5 14.9 L 23.1 14 Z" fill="#FFFFFF" fill-opacity="0.82"/>
	  <path d="M 9.2 8.5 L 10 10.7 L 12.2 11.5 L 10 12.3 L 9.2 14.5 L 8.4 12.3 L 6.2 11.5 L 8.4 10.7 Z" fill="{C2}" fill-opacity="0.9"/>
	  <path d="M 38.8 8.5 L 39.6 10.7 L 41.8 11.5 L 39.6 12.3 L 38.8 14.5 L 38 12.3 L 35.8 11.5 L 38 10.7 Z" fill="{C2}" fill-opacity="0.9"/>
	</svg>""",

	# ==================== 高阶神木 / 仙矿 / 丹药 / 仙兵仙衣 / 灵符（33 枚独立精绘） ====================
	"item_chiyan_wutong": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 9.5 29.5 L 33.5 19.5 A 6.2 6.2 0 0 1 38.2 31 L 14.2 41 A 6.2 6.2 0 0 0 9.5 29.5 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <circle cx="12" cy="35.2" r="6" fill="{C2}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.1"/>
	  <circle cx="12" cy="35.2" r="2.2" fill="{C2}"/>
	  <path d="M 20 31.5 L 32 26.5 M 23 34.5 L 34 29.8" fill="none" stroke="{C1}" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.58"/>
	  <path d="M 23.5 23.5 C 16.5 22 12.5 16.5 14 11.5 C 17 13.8 19.2 14.2 21 15 C 20 10.5 22.5 7 25.5 5.2 C 28 8.8 29 12.5 28 15.5 C 31.2 13.8 34.2 14 36.2 16 C 34 20.5 29 23.2 23.5 23.5 Z" fill="{C2}" fill-opacity="0.34" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
	  <path d="M 24.2 22.5 L 25.2 10.2 M 23.8 19 L 17.5 15.2 M 24.8 18.8 L 31.5 16.8" fill="none" stroke="{C2}" stroke-width="1.4" stroke-linecap="round"/>
	  <circle cx="11" cy="19.5" r="1.4" fill="{C2}" fill-opacity="0.82"/>
	  <circle cx="38.5" cy="10.5" r="1.6" fill="{C2}" fill-opacity="0.88"/>
	</svg>""",

	"item_jianmu": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 16 41.5 Q 23.5 39 32 41.5" fill="none" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
	  <path d="M 24 40 C 23 32 25.5 26 24 18 M 24 28 C 17 25 12 22 8.5 16.5 M 24 23 C 31 20 35.5 17 39.5 12" fill="none" stroke="{C1}" stroke-width="2.5" stroke-linecap="round"/>
	  <path d="M 24 18 C 20.5 14 21 9.5 24 6.2 C 27 9.5 27.5 14 24 18 Z" fill="{C2}" fill-opacity="0.36" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 11.5 19.5 Q 11.5 26 9.5 30 M 36 15.2 Q 36 22 38 26.5" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	  <polygon points="9.5,28.5 12,31.5 9.5,34.5 7,31.5" fill="{C2}" fill-opacity="0.82" stroke="{C1}" stroke-width="1.3" stroke-linejoin="round"/>
	  <polygon points="38,25 40.5,28 38,31 35.5,28" fill="{C2}" fill-opacity="0.82" stroke="{C1}" stroke-width="1.3" stroke-linejoin="round"/>
	  <circle cx="16.5" cy="12" r="1.5" fill="{C2}" fill-opacity="0.85"/>
	  <circle cx="31.5" cy="9.5" r="1.3" fill="{C2}" fill-opacity="0.72"/>
	</svg>""",

	"item_xingchen_sang": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 9 18.5 Q 24 6.5 39 14.5" fill="none" stroke="{C2}" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.65" stroke-dasharray="5 4"/>
	  <path d="M 8 38 C 14 28 24 20 39.5 16.5" fill="none" stroke="{C1}" stroke-width="2.8" stroke-linecap="round"/>
	  <path d="M 22 24.5 Q 26 17.5 31.5 14.5" fill="none" stroke="{C1}" stroke-width="2.0" stroke-linecap="round"/>
	  <path d="M 17 28 Q 10.5 25.5 9 20.5 Q 14.5 20.5 17 28 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round"/>
	  <path d="M 29.5 18 Q 34.5 12 40 12 Q 37.5 17.5 29.5 18 Z" fill="{C2}" fill-opacity="0.28" stroke="{C1}" stroke-width="1.8" stroke-linejoin="round"/>
	  <path d="M 22.5 24.5 L 22.5 28.5 M 33 19.2 L 33 23.5" fill="none" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
	  <polygon points="22.5,28 25.5,31.5 22.5,35 19.5,31.5" fill="{C2}" fill-opacity="0.85" stroke="{C1}" stroke-width="1.5" stroke-linejoin="round"/>
	  <circle cx="19.5" cy="35.5" r="2.0" fill="{C2}" stroke="{C1}" stroke-width="1.3"/>
	  <circle cx="25.5" cy="35.5" r="2.0" fill="{C2}" stroke="{C1}" stroke-width="1.3"/>
	  <polygon points="33,23 36.2,26.8 33,30.6 29.8,26.8" fill="{C2}" fill-opacity="0.85" stroke="{C1}" stroke-width="1.5" stroke-linejoin="round"/>
	  <path d="M 13.5 9.5 L 14.3 11.7 L 16.5 12.5 L 14.3 13.3 L 13.5 15.5 L 12.7 13.3 L 10.5 12.5 L 12.7 11.7 Z" fill="{C2}"/>
	</svg>""",

	"item_hundun_vine": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 15 41.5 C 12 32 36 28 33 18 C 30.5 10.5 20 11 16 7.5" fill="none" stroke="{C1}" stroke-width="2.6" stroke-linecap="round"/>
	  <path d="M 33 41.5 C 36 32 12 28 15 18 C 17.5 10.5 28 11 32 7.5" fill="none" stroke="{C1}" stroke-width="2.6" stroke-linecap="round"/>
	  <circle cx="24" cy="24.5" r="7.2" fill="{C2}" fill-opacity="0.24" stroke="{C1}" stroke-width="2.0"/>
	  <path d="M 24 17.3 A 3.6 3.6 0 0 1 24 24.5 A 3.6 3.6 0 0 0 24 31.7" fill="none" stroke="{C2}" stroke-width="1.9" stroke-linecap="round"/>
	  <circle cx="24" cy="20.9" r="1.4" fill="{C2}"/>
	  <circle cx="24" cy="28.1" r="1.4" fill="{C1}"/>
	  <path d="M 13.5 19 Q 8 18 6.5 13.5 Q 11.5 14 13.5 19 Z M 34.5 29.5 Q 40 30.5 41.5 35 Q 36.5 34.5 34.5 29.5 Z" fill="{C2}" fill-opacity="0.38" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round"/>
	  <circle cx="37.5" cy="14" r="1.5" fill="{C2}"/>
	  <circle cx="10.5" cy="34.5" r="1.4" fill="{C2}" fill-opacity="0.78"/>
	</svg>""",

	"item_worldtree": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="24" r="19.2" fill="none" stroke="{C2}" stroke-width="1.4" stroke-opacity="0.58"/>
	  <circle cx="24" cy="24" r="15.8" fill="none" stroke="{C1}" stroke-width="1.0" stroke-opacity="0.28" stroke-dasharray="6 4"/>
	  <path d="M 12.5 26 C 12.5 18.8 35.5 18.8 35.5 26 C 35.5 34.5 31 39.5 24 39.5 C 17 39.5 12.5 34.5 12.5 26 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <ellipse cx="24" cy="28.8" rx="8.2" ry="6.8" fill="none" stroke="{C1}" stroke-width="1.4" stroke-opacity="0.55"/>
	  <path d="M 24 24.2 L 25.3 27.5 L 28.6 28.8 L 25.3 30.1 L 24 33.4 L 22.7 30.1 L 19.4 28.8 L 22.7 27.5 Z" fill="{C2}"/>
	  <path d="M 24 19.5 L 24 9.5 M 24 15.5 Q 17.5 14 14 9.5 M 24 15.5 Q 30.5 14 34 9.5" fill="none" stroke="{C1}" stroke-width="2.1" stroke-linecap="round"/>
	  <circle cx="24" cy="8.2" r="2.1" fill="{C2}"/>
	  <circle cx="13.5" cy="9.2" r="1.7" fill="{C2}"/>
	  <circle cx="34.5" cy="9.2" r="1.7" fill="{C2}"/>
	</svg>""",

	"item_hanyu": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <polygon points="8,39.5 12,30 36,30 40,39.5" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <polygon points="18.5,33 17.5,14.5 24,7.5 30.5,14.5 29.5,33" fill="{C2}" fill-opacity="0.30" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 24 7.5 L 24 33 M 17.5 14.5 L 24 17.8 L 30.5 14.5" fill="none" stroke="{C2}" stroke-width="1.5" stroke-linejoin="round"/>
	  <polygon points="11.5,33.5 10.5,22 15.5,18.5 18,24 17.5,33.5" fill="{C2}" fill-opacity="0.20" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <polygon points="30.5,33.5 31,23.5 35.5,20 37.5,25 36.5,33.5" fill="{C2}" fill-opacity="0.20" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 38 9 L 38 15 M 35.4 10.5 L 40.6 13.5 M 40.6 10.5 L 35.4 13.5" fill="none" stroke="{C2}" stroke-width="1.5" stroke-linecap="round"/>
	</svg>""",

	"item_jiuyou_crystal": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <polygon points="14,39.5 21.5,7.5 29,15 31,39.5" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <polygon points="7.5,39.5 9,20.5 15.5,17 17.5,39.5" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
	  <polygon points="30.5,39.5 33,19 39.5,23 38.5,39.5" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
	  <path d="M 22.5 11.5 L 20.5 22 L 24.2 26.5 L 22 36.5" fill="none" stroke="{C2}" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
	  <path d="M 11.5 22.5 L 13 35 M 35 23.5 L 34 35" fill="none" stroke="{C2}" stroke-width="1.5" stroke-linecap="round" stroke-opacity="0.8"/>
	  <path d="M 35.5 15 Q 38 11.5 35.5 8 Q 33 11.5 35.5 15 Z" fill="{C2}" fill-opacity="0.82"/>
	  <circle cx="11.5" cy="11.5" r="1.5" fill="{C2}" fill-opacity="0.75"/>
	</svg>""",

	"item_xingyun_iron": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <ellipse cx="24" cy="24" rx="19.5" ry="7.8" transform="rotate(-24 24 24)" fill="none" stroke="{C2}" stroke-width="1.6" stroke-opacity="0.75"/>
	  <polygon points="12,35.5 9.5,22 17.5,11.5 31.5,12.5 38.5,23.5 34.5,36.5 22,39.5" fill="{C1}" fill-opacity="0.24" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 17.5 11.5 L 23.5 21.5 L 38.5 23.5 M 23.5 21.5 L 22 39.5 M 9.5 22 L 23.5 21.5" fill="none" stroke="{C1}" stroke-width="1.5" stroke-opacity="0.58"/>
	  <path d="M 16 20 L 23.5 21.5 L 29.5 17.5 M 23.5 21.5 L 27.5 30.5" fill="none" stroke="{C2}" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
	  <circle cx="23.5" cy="21.5" r="2.2" fill="{C2}"/>
	  <path d="M 39.5 9 L 40.3 11.2 L 42.5 12 L 40.3 12.8 L 39.5 15 L 38.7 12.8 L 36.5 12 L 38.7 11.2 Z" fill="{C2}"/>
	  <circle cx="8.5" cy="35" r="1.6" fill="{C2}" fill-opacity="0.8"/>
	</svg>""",

	"item_hundun_stone": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <polygon points="24,6.5 35.5,16.5 32.5,29.5 24,33.5 15.5,29.5 12.5,16.5" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 24 6.5 L 24 14.5 M 12.5 16.5 L 19 19.5 M 35.5 16.5 L 29 19.5 M 15.5 29.5 L 20.5 25 M 32.5 29.5 L 27.5 25" fill="none" stroke="{C1}" stroke-width="1.4" stroke-opacity="0.55"/>
	  <polygon points="24,14.5 29,20.5 24,26.5 19,20.5" fill="{C2}" fill-opacity="0.72" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round"/>
	  <path d="M 7.5 35.5 C 14 39.5 34 39.5 40.5 35.5 M 11.5 40.2 C 18 43 30 43 36.5 40.2" fill="none" stroke="{C2}" stroke-width="1.9" stroke-linecap="round"/>
	  <polygon points="6.5,22 9.5,20.5 9,24" fill="{C1}" fill-opacity="0.3" stroke="{C1}" stroke-width="1.3" stroke-linejoin="round"/>
	  <polygon points="41.5,22 38.5,20.5 39,24" fill="{C1}" fill-opacity="0.3" stroke="{C1}" stroke-width="1.3" stroke-linejoin="round"/>
	</svg>""",

	"item_hongmeng_gold": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="24" r="19" fill="none" stroke="{C2}" stroke-width="1.5" stroke-opacity="0.62"/>
	  <circle cx="24" cy="24" r="15.4" fill="none" stroke="{C1}" stroke-width="1.0" stroke-opacity="0.30" stroke-dasharray="5 4"/>
	  <polygon points="24,7.5 34,17.5 31.5,33.5 24,40.5 16.5,33.5 14,17.5" fill="{C2}" fill-opacity="0.32" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <polygon points="24,13.5 29.2,21.5 24,33.5 18.8,21.5" fill="{C2}" fill-opacity="0.68" stroke="{C1}" stroke-width="1.5" stroke-linejoin="round"/>
	  <path d="M 14 17.5 L 18.8 21.5 M 34 17.5 L 29.2 21.5 M 16.5 33.5 L 18.8 21.5 M 31.5 33.5 L 29.2 21.5" fill="none" stroke="{C1}" stroke-width="1.3" stroke-opacity="0.6"/>
	  <path d="M 9 20 L 11.5 24 L 9 28 M 39 20 L 36.5 24 L 39 28" fill="none" stroke="{C2}" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/>
	  <path d="M 9.5 8.5 L 10.3 10.7 L 12.5 11.5 L 10.3 12.3 L 9.5 14.5 L 8.7 12.3 L 6.5 11.5 L 8.7 10.7 Z" fill="{C2}"/>
	  <path d="M 38.5 8.5 L 39.3 10.7 L 41.5 11.5 L 39.3 12.3 L 38.5 14.5 L 37.7 12.3 L 35.5 11.5 L 37.7 10.7 Z" fill="{C2}"/>
	</svg>""",

	"item_trib_huashen": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="23.5" r="12.5" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.2"/>
	  <path d="M 24 15.8 Q 28.2 23.5 24 31.2 Q 19.8 23.5 24 15.8 Z" fill="{C2}" fill-opacity="0.72" stroke="{C1}" stroke-width="1.5"/>
	  <circle cx="24" cy="23.5" r="2.0" fill="#FFFFFF" fill-opacity="0.8"/>
	  <path d="M 10.5 33 Q 16 39.5 24 39.5 Q 32 39.5 37.5 33 Q 31 35 24 35 Q 17 35 10.5 33 Z" fill="{C2}" fill-opacity="0.34" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <polygon points="24,5 26.5,8 24,11 21.5,8" fill="{C2}" stroke="{C1}" stroke-width="1.3" stroke-linejoin="round"/>
	  <circle cx="11" cy="14" r="1.4" fill="{C2}"/>
	  <circle cx="37" cy="14" r="1.4" fill="{C2}"/>
	</svg>""",

	"item_trib_lianxu": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <ellipse cx="24" cy="24" rx="19.2" ry="8.5" transform="rotate(-22 24 24)" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <circle cx="24" cy="24" r="11.8" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.2"/>
	  <path d="M 24 17.5 A 6.5 6.5 0 1 1 18.2 27 A 4 4 0 1 1 26.5 23.5" fill="none" stroke="{C2}" stroke-width="2.1" stroke-linecap="round"/>
	  <circle cx="24" cy="24" r="1.8" fill="{C2}"/>
	  <path d="M 38.5 8 L 39.3 10.2 L 41.5 11 L 39.3 11.8 L 38.5 14 L 37.7 11.8 L 35.5 11 L 37.7 10.2 Z" fill="{C2}"/>
	  <circle cx="10" cy="36.5" r="1.8" fill="{C2}" fill-opacity="0.85"/>
	</svg>""",

	"item_trib_heti": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 10.5 16 A 16.5 16.5 0 0 1 37.5 16 M 37.5 32 A 16.5 16.5 0 0 1 10.5 32" fill="none" stroke="{C2}" stroke-width="1.9" stroke-linecap="round"/>
	  <circle cx="24" cy="24" r="11.5" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.2"/>
	  <path d="M 24 12.5 A 5.75 5.75 0 0 1 24 24 A 5.75 5.75 0 0 0 24 35.5" fill="none" stroke="{C2}" stroke-width="2.1" stroke-linecap="round"/>
	  <circle cx="24" cy="18.3" r="1.9" fill="{C2}"/>
	  <circle cx="24" cy="29.7" r="1.9" fill="{C1}"/>
	  <polygon points="24,4.5 26.8,7.8 24,11.1 21.2,7.8" fill="{C2}"/>
	  <polygon points="24,36.9 26.8,40.2 24,43.5 21.2,40.2" fill="{C2}"/>
	</svg>""",

	"item_trib_dacheng": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="24" r="18.2" fill="none" stroke="{C2}" stroke-width="1.5" stroke-opacity="0.72"/>
	  <path d="M 24 3 L 24 6.5 M 24 41.5 L 24 45 M 3 24 L 6.5 24 M 41.5 24 L 45 24 M 9.2 9.2 L 11.8 11.8 M 36.2 36.2 L 38.8 38.8 M 38.8 9.2 L 36.2 11.8 M 11.8 36.2 L 9.2 38.8" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <circle cx="24" cy="24" r="12.2" fill="{C2}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.2"/>
	  <circle cx="24" cy="24" r="8.2" fill="none" stroke="{C1}" stroke-width="1.4" stroke-opacity="0.65"/>
	  <path d="M 24 17 L 25.8 22.2 L 31 24 L 25.8 25.8 L 24 31 L 22.2 25.8 L 17 24 L 22.2 22.2 Z" fill="{C2}" stroke="{C1}" stroke-width="1.2" stroke-linejoin="round"/>
	</svg>""",

	"item_huashen_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="26.5" r="12" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.2"/>
	  <path d="M 14.5 23.5 Q 24 27 33.5 23.5 M 14.5 29.5 Q 24 33 33.5 29.5" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <path d="M 19 14.5 Q 17.5 9.5 21 6.5 Q 22.5 10.5 24 11.5 Q 25.5 8 28.5 6.5 Q 30.5 10.5 29 14.5" fill="{C2}" fill-opacity="0.36" stroke="{C2}" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
	  <circle cx="19.5" cy="21" r="1.4" fill="#FFFFFF" fill-opacity="0.75"/>
	</svg>""",

	"item_lianxu_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <polygon points="18.5,11.5 29.5,11.5 36.5,18.5 36.5,29.5 29.5,36.5 18.5,36.5 11.5,29.5 11.5,18.5" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <polygon points="24,15.5 32.5,24 24,32.5 15.5,24" fill="{C2}" fill-opacity="0.28" stroke="{C2}" stroke-width="1.7" stroke-linejoin="round"/>
	  <circle cx="24" cy="24" r="3.0" fill="{C2}"/>
	  <path d="M 10 39.5 Q 17 42.5 24 40 Q 31 42.5 38 39.5" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <circle cx="24" cy="7.5" r="1.6" fill="{C2}"/>
	</svg>""",

	"item_heti_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <ellipse cx="24" cy="24" rx="18" ry="7.2" transform="rotate(-32 24 24)" fill="none" stroke="{C2}" stroke-width="1.6" stroke-opacity="0.78"/>
	  <ellipse cx="24" cy="24" rx="18" ry="7.2" transform="rotate(32 24 24)" fill="none" stroke="{C1}" stroke-width="1.5" stroke-opacity="0.52"/>
	  <circle cx="24" cy="24" r="10.2" fill="{C2}" fill-opacity="0.24" stroke="{C1}" stroke-width="2.2"/>
	  <circle cx="24" cy="24" r="4.2" fill="{C2}" stroke="{C1}" stroke-width="1.4"/>
	  <circle cx="11" cy="13.5" r="1.5" fill="{C2}"/>
	  <circle cx="37" cy="34.5" r="1.5" fill="{C2}"/>
	</svg>""",

	"item_dacheng_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="22" r="16.5" fill="none" stroke="{C2}" stroke-width="1.4" stroke-opacity="0.55" stroke-dasharray="7 4"/>
	  <circle cx="24" cy="22" r="10.5" fill="{C2}" fill-opacity="0.30" stroke="{C1}" stroke-width="2.2"/>
	  <path d="M 24 16 L 25.4 20.6 L 30 22 L 25.4 23.4 L 24 28 L 22.6 23.4 L 18 22 L 22.6 20.6 Z" fill="{C2}"/>
	  <path d="M 10 34.5 C 14.5 31.5 19 33.5 24 37 C 29 33.5 33.5 31.5 38 34.5 C 34 40 29 41.5 24 41.5 C 19 41.5 14 40 10 34.5 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 24 3.5 L 24.8 5.7 L 27 6.5 L 24.8 7.3 L 24 9.5 L 23.2 7.3 L 21 6.5 L 23.2 5.7 Z" fill="{C2}"/>
	</svg>""",

	"item_qingxin_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 24 6.5 L 38 12.5 L 36.5 26.5 C 35.5 34.5 29.8 39.5 24 42 C 18.2 39.5 12.5 34.5 11.5 26.5 L 10 12.5 Z" fill="{C1}" fill-opacity="0.12" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
	  <circle cx="24" cy="23.5" r="9.2" fill="{C2}" fill-opacity="0.24" stroke="{C1}" stroke-width="2.0"/>
	  <path d="M 24 17.5 C 21.5 20.8 21.5 26.2 24 29.5 C 26.5 26.2 26.5 20.8 24 17.5 Z" fill="{C2}" fill-opacity="0.88"/>
	  <path d="M 17.8 23.5 Q 20.8 20.5 24 23.5 Q 27.2 20.5 30.2 23.5" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round"/>
	</svg>""",

	"item_jiuzhuan_pill": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="24" r="10.5" fill="{C2}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.2"/>
	  <path d="M 10 18 C 10 9.5 22 7.5 30 11.5 M 38 30 C 38 38.5 26 40.5 18 36.5" fill="none" stroke="{C2}" stroke-width="2.1" stroke-linecap="round"/>
	  <polygon points="31.5,12.2 27.5,8.5 28,13.5" fill="{C2}"/>
	  <polygon points="16.5,35.8 20.5,39.5 20,34.5" fill="{C2}"/>
	  <path d="M 24 18.5 L 24 29.5 M 18.5 24 L 29.5 24" fill="none" stroke="{C2}" stroke-width="2.4" stroke-linecap="round"/>
	</svg>""",

	"equip_jiuyou_sword": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 16.5 26.5 L 33 10 L 41 6.5 L 37.5 14.5 L 21 31 Z" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 20 27.5 L 38 9.5" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <path d="M 24.5 18.5 L 23.2 15.5 L 27 16 M 30.5 12.5 L 29.2 9.5 L 33 10" fill="none" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round"/>
	  <path d="M 11.5 22 Q 16.5 26.5 21 31 Q 23 34 25.5 36.5 Q 20 35.5 16.5 32 Q 13 28.5 11.5 22 Z" fill="{C2}" fill-opacity="0.52" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
	  <path d="M 16.5 31.5 L 10.5 37.5" fill="none" stroke="{C1}" stroke-width="3.0" stroke-linecap="round"/>
	  <circle cx="9" cy="39" r="2.6" fill="{C2}" stroke="{C1}" stroke-width="1.8"/>
	  <path d="M 32 28 Q 35.5 24.5 34 20.5 Q 31 24 32 28 Z" fill="{C2}" fill-opacity="0.82"/>
	</svg>""",

	"equip_mingyuan_armor": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 16 11 L 8 13 L 5.5 21.5 L 13 23.5 L 14.5 39.5 L 24 42 L 33.5 39.5 L 35 23.5 L 42.5 21.5 L 40 13 L 32 11 L 24 14.5 Z" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <polygon points="8,13 5,7 12.5,11.5" fill="{C2}" fill-opacity="0.55" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round"/>
	  <polygon points="40,13 43,7 35.5,11.5" fill="{C2}" fill-opacity="0.55" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round"/>
	  <polygon points="24,18.5 28.5,24 24,29.5 19.5,24" fill="{C2}" fill-opacity="0.82" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round"/>
	  <path d="M 14.5 31.5 L 24 34 L 33.5 31.5 M 24 34 L 24 41.5" fill="none" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
	</svg>""",

	"equip_xinghe_sword": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 17.8 26.8 L 35.5 9.5 L 41.5 6.5 L 38.5 12.5 L 21.2 30.2 Z" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 20.5 27.5 L 39 9" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <path d="M 12.2 23.5 Q 18 28.5 24.5 35.8 Q 19 32.8 16.5 30.3 Q 14 27.8 12.2 23.5 Z" fill="{C2}" fill-opacity="0.45" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
	  <path d="M 16.2 31.8 L 10.5 37.5" fill="none" stroke="{C1}" stroke-width="2.8" stroke-linecap="round"/>
	  <polygon points="8.8,36.2 11.8,39.2 8.8,42.2 5.8,39.2" fill="{C2}" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round"/>
	  <path d="M 9.5 16.5 Q 19.5 8.5 32.5 7.5 M 25.5 39.5 Q 36 33.5 40 20.5" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round" stroke-opacity="0.82"/>
	  <path d="M 14.5 10 L 15.2 12 L 17.2 12.7 L 15.2 13.4 L 14.5 15.4 L 13.8 13.4 L 11.8 12.7 L 13.8 12 Z" fill="{C2}"/>
	</svg>""",

	"equip_xingchen_robe": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 18.5 8.5 L 24 13.5 L 29.5 8.5 L 42 16.5 L 39 27.5 L 33.5 24.5 L 36 41.5 L 12 41.5 L 14.5 24.5 L 9 27.5 L 6 16.5 Z" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 18.5 8.5 L 28 24.5 M 29.5 8.5 L 23.5 18.5" fill="none" stroke="{C1}" stroke-width="1.8" stroke-linecap="round"/>
	  <path d="M 14 27.5 L 34 27.5 M 21.5 27.5 L 19.5 37.5 M 26.5 27.5 L 28.5 37.5" fill="none" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
	  <path d="M 16.5 18.5 L 21 16 L 26.5 18.5 L 31.5 16" fill="none" stroke="{C2}" stroke-width="1.3" stroke-linecap="round"/>
	  <circle cx="16.5" cy="18.5" r="1.4" fill="{C2}"/>
	  <circle cx="26.5" cy="18.5" r="1.4" fill="{C2}"/>
	  <circle cx="31.5" cy="16" r="1.3" fill="{C2}"/>
	  <circle cx="24" cy="34.5" r="1.6" fill="{C2}"/>
	</svg>""",

	"equip_hundun_axe": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 8.5 38.2 L 35.5 11.2 L 37.8 13.5 L 10.8 40.5 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <polygon points="39.5,8.5 34.5,11.2 37.8,14.5" fill="{C2}" stroke="{C1}" stroke-width="1.6" stroke-linejoin="round"/>
	  <path d="M 27.5 16.5 C 23 11 16 8.5 10.5 10.5 C 12 17.5 15.5 22.5 22.5 24.5 Z" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 32.5 21.5 C 38 26 40.5 33 38.5 38.5 C 31.5 37 26.5 33.5 24.5 26.5 Z" fill="{C1}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 12.8 12.2 C 14.2 16.8 16.8 20.5 21 22.5 M 36.8 36.2 C 32.2 34.8 28.5 32.2 26.5 28" fill="none" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
	  <circle cx="27.5" cy="21.5" r="4.0" fill="{C2}" fill-opacity="0.82" stroke="{C1}" stroke-width="1.8"/>
	  <circle cx="9.2" cy="39.5" r="2.2" fill="{C2}" stroke="{C1}" stroke-width="1.7"/>
	</svg>""",

	"equip_hunyuan_robe": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 17 9.5 Q 24 13.5 31 9.5 L 41.5 14.5 L 40 24 L 34 23 L 36.5 41 L 24 43 L 11.5 41 L 14 23 L 8 24 L 6.5 14.5 Z" fill="{C1}" fill-opacity="0.20" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 9 16.5 Q 12 19.5 16 17.5 M 39 16.5 Q 36 19.5 32 17.5" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <circle cx="24" cy="22.5" r="5.6" fill="{C2}" fill-opacity="0.28" stroke="{C1}" stroke-width="1.9"/>
	  <path d="M 24 16.9 A 2.8 2.8 0 0 1 24 22.5 A 2.8 2.8 0 0 0 24 28.1" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <path d="M 13.5 31.5 Q 24 34.5 34.5 31.5 M 19 33 L 17.5 41.5 M 29 33 L 30.5 41.5" fill="none" stroke="{C2}" stroke-width="1.7" stroke-linecap="round"/>
	</svg>""",

	"equip_hongmeng_sword": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="24" r="19" fill="none" stroke="{C2}" stroke-width="1.4" stroke-opacity="0.58" stroke-dasharray="10 5"/>
	  <path d="M 16.5 26 L 34.5 8 L 41.5 5.5 L 39 12.5 L 21 30.5 Z" fill="{C2}" fill-opacity="0.26" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 19.5 27.5 L 38.5 8.5" fill="none" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
	  <path d="M 9.5 20.5 L 17.5 25 L 22 29.5 L 26.5 37.5 L 21.5 35.5 L 15.5 31.5 L 11.5 25.5 Z" fill="{C2}" fill-opacity="0.65" stroke="{C1}" stroke-width="2.0" stroke-linejoin="round"/>
	  <path d="M 15.8 31.2 L 9.5 37.5" fill="none" stroke="{C1}" stroke-width="3.0" stroke-linecap="round"/>
	  <path d="M 8 36.2 L 9.2 38.2 L 11.2 39.4 L 9.2 40.6 L 8 42.6 L 6.8 40.6 L 4.8 39.4 L 6.8 38.2 Z" fill="{C2}"/>
	  <path d="M 10.5 8 L 11.3 10.2 L 13.5 11 L 11.3 11.8 L 10.5 14 L 9.7 11.8 L 7.5 11 L 9.7 10.2 Z" fill="{C2}"/>
	</svg>""",

	"equip_zaohua_robe": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 7.5 22 C 3.5 13 11 5 24 5 C 37 5 44.5 13 40.5 22" fill="none" stroke="{C2}" stroke-width="2.0" stroke-linecap="round" stroke-opacity="0.82"/>
	  <path d="M 18 11 L 24 15.5 L 30 11 L 42 18.5 L 39.5 30 L 33.5 26.5 L 37.5 42.5 L 24 40 L 10.5 42.5 L 14.5 26.5 L 8.5 30 L 6 18.5 Z" fill="{C2}" fill-opacity="0.22" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 16.5 14.5 Q 24 19.5 31.5 14.5" fill="none" stroke="{C2}" stroke-width="1.8" stroke-linecap="round"/>
	  <path d="M 24 19.5 L 25.4 23.1 L 29 24.5 L 25.4 25.9 L 24 29.5 L 22.6 25.9 L 19 24.5 L 22.6 23.1 Z" fill="{C2}"/>
	  <path d="M 14.5 31.5 Q 24 34 33.5 31.5 M 24 33 L 24 40" fill="none" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
	  <circle cx="24" cy="5.2" r="1.8" fill="{C2}"/>
	</svg>""",

	"item_xuanbing_talisman": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 13.5 6.5 L 34.5 6.5 L 34.5 41.5 L 24 38.5 L 13.5 41.5 Z" fill="{C1}" fill-opacity="0.14" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 17.5 11 L 30.5 11 M 18 34 L 30 34" fill="none" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
	  <polygon points="24,14.5 30.8,18.5 30.8,26.5 24,30.5 17.2,26.5 17.2,18.5" fill="{C2}" fill-opacity="0.28" stroke="{C2}" stroke-width="1.9" stroke-linejoin="round"/>
	  <path d="M 24 16.5 L 24 28.5 M 18.8 19.5 L 29.2 25.5 M 29.2 19.5 L 18.8 25.5" fill="none" stroke="{C2}" stroke-width="1.5" stroke-linecap="round"/>
	  <path d="M 8 15 L 8 19 M 6 17 L 10 17 M 40 28 L 40 32 M 38 30 L 42 30" fill="none" stroke="{C2}" stroke-width="1.5" stroke-linecap="round"/>
	</svg>""",

	"item_jiuyou_ward": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <polygon points="15.5,6 32.5,6 35,9.5 35,41.5 13,41.5 13,9.5" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.1" stroke-linejoin="round"/>
	  <path d="M 19 10.5 L 29 10.5 M 24 10.5 L 24 35.5 M 18 16.5 L 30 16.5 M 17.5 29.5 L 30.5 29.5" fill="none" stroke="{C2}" stroke-width="1.9" stroke-linecap="round"/>
	  <polygon points="24,19 28.5,23 24,27 19.5,23" fill="{C2}" fill-opacity="0.65" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round"/>
	  <path d="M 8 26 Q 5.5 22 8.5 18 Q 10 22 8 26 Z M 40 26 Q 42.5 22 39.5 18 Q 38 22 40 26 Z" fill="{C2}" fill-opacity="0.72"/>
	</svg>""",

	"item_xingyun_ward": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <rect x="13" y="6.5" width="22" height="35" rx="2.2" fill="{C1}" fill-opacity="0.14" stroke="{C1}" stroke-width="2.1"/>
	  <path d="M 17 11.5 L 31 11.5 M 18 36.5 L 30 36.5" fill="none" stroke="{C1}" stroke-width="1.6" stroke-linecap="round"/>
	  <path d="M 24 14.2 L 26.2 21.8 L 31.5 24 L 26.2 26.2 L 24 33.8 L 21.8 26.2 L 16.5 24 L 21.8 21.8 Z" fill="{C2}" fill-opacity="0.78" stroke="{C1}" stroke-width="1.3" stroke-linejoin="round"/>
	  <path d="M 6.5 34.5 Q 20 20 41.5 11.5" fill="none" stroke="{C2}" stroke-width="2.0" stroke-linecap="round"/>
	  <circle cx="41.5" cy="11.5" r="2.0" fill="{C2}"/>
	  <circle cx="8" cy="14" r="1.4" fill="{C2}" fill-opacity="0.8"/>
	</svg>""",

	"item_hundun_ward": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <rect x="12" y="6.5" width="24" height="35" rx="2.5" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.2"/>
	  <rect x="15.5" y="10" width="17" height="28" rx="1.2" fill="none" stroke="{C2}" stroke-width="1.3" stroke-opacity="0.72"/>
	  <polygon points="24,14.5 30.8,24 24,33.5 17.2,24" fill="{C2}" fill-opacity="0.34" stroke="{C2}" stroke-width="1.9" stroke-linejoin="round"/>
	  <rect x="20.2" y="20.2" width="7.6" height="7.6" fill="{C2}" fill-opacity="0.72" stroke="{C1}" stroke-width="1.5"/>
	  <circle cx="15.5" cy="10" r="1.3" fill="{C2}"/>
	  <circle cx="32.5" cy="10" r="1.3" fill="{C2}"/>
	  <circle cx="15.5" cy="38" r="1.3" fill="{C2}"/>
	  <circle cx="32.5" cy="38" r="1.3" fill="{C2}"/>
	</svg>""",

	"item_hongmeng_thunder": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="24" r="19.5" fill="none" stroke="{C2}" stroke-width="1.5" stroke-opacity="0.62" stroke-dasharray="9 4"/>
	  <rect x="13" y="6" width="22" height="36" rx="2.2" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.2"/>
	  <path d="M 16.8 11.2 Q 19.2 8.8 21.6 11.2 Q 24 8.8 26.4 11.2 Q 28.8 8.8 31.2 11.2" fill="none" stroke="{C2}" stroke-width="1.7" stroke-linecap="round"/>
	  <polygon points="26.5,14.5 18.2,24.8 23.6,24.8 20.5,35.5 30.2,23.2 24.8,23.2" fill="{C2}" fill-opacity="0.88" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round"/>
	  <path d="M 7.5 17 L 11 19 L 8.5 22.5 M 40.5 25 L 37 27 L 39.5 30.5" fill="none" stroke="{C2}" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
	</svg>""",

	# ==================== 高阶灵种（5 枚，新灵药种植闭环） ====================
	"seed_biyu": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 24 10 C 31.5 16.5 34.5 24 32.5 31.5 C 30.8 37 27.5 39.5 24 39.5 C 20.5 39.5 17.2 37 15.5 31.5 C 13.5 24 16.5 16.5 24 10 Z" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 24 18 L 24 28 M 24 28 Q 20.5 31 19.5 34.5 M 24 28 Q 27.5 31 28.5 34.5" fill="none" stroke="{C2}" stroke-width="1.9" stroke-linecap="round"/>
	  <circle cx="24" cy="16.5" r="2.1" fill="{C2}"/>
	  <path d="M 24 10 Q 20 6 16.5 6.8 M 24 10 Q 28 6 31.5 6.8" fill="none" stroke="{C2}" stroke-width="1.7" stroke-linecap="round"/>
	</svg>""",

	"seed_longxue": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <path d="M 24 8.5 C 32 15.5 36 24.5 32.5 33 C 30.2 38.2 27 40 24 40 C 21 40 17.8 38.2 15.5 33 C 12 24.5 16 15.5 24 8.5 Z" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 24 17.5 Q 28.2 23.5 24 29.5 Q 19.8 23.5 24 17.5 Z" fill="{C2}" fill-opacity="0.82" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round"/>
	  <path d="M 16.5 29 Q 20 27 22 29.5 M 31.5 29 Q 28 27 26 29.5" fill="none" stroke="{C2}" stroke-width="1.5" stroke-linecap="round"/>
	  <path d="M 35 12 Q 37 15 35 16.8 Q 33 15 35 12 Z" fill="{C2}" fill-opacity="0.85"/>
	</svg>""",

	"seed_taiyi": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <ellipse cx="24" cy="23.5" rx="11.5" ry="13.5" fill="{C1}" fill-opacity="0.16" stroke="{C1}" stroke-width="2.2"/>
	  <path d="M 24 10 C 19 16 19 31 24 37 M 24 10 C 29 16 29 31 24 37" fill="none" stroke="{C1}" stroke-width="1.3" stroke-opacity="0.45"/>
	  <path d="M 24 16.5 C 21 20.5 21 26.5 24 30.5 C 27 26.5 27 20.5 24 16.5 Z" fill="{C2}" fill-opacity="0.72" stroke="{C1}" stroke-width="1.4" stroke-linejoin="round"/>
	  <path d="M 10.5 39.5 Q 17.2 42 24 39.5 Q 30.8 37 37.5 39.5" fill="none" stroke="{C2}" stroke-width="1.9" stroke-linecap="round"/>
	  <path d="M 37.5 8.5 L 38.2 10.5 L 40.2 11.2 L 38.2 11.9 L 37.5 13.9 L 36.8 11.9 L 34.8 11.2 L 36.8 10.5 Z" fill="{C2}"/>
	</svg>""",

	"seed_hundun": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="24" r="16.5" fill="none" stroke="{C2}" stroke-width="1.4" stroke-opacity="0.58" stroke-dasharray="8 5"/>
	  <polygon points="24,10.5 34.5,17.2 34.5,30.8 24,37.5 13.5,30.8 13.5,17.2" fill="{C1}" fill-opacity="0.18" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <circle cx="24" cy="24" r="6.8" fill="{C2}" fill-opacity="0.22" stroke="{C1}" stroke-width="1.8"/>
	  <path d="M 24 17.2 A 3.4 3.4 0 0 1 24 24 A 3.4 3.4 0 0 0 24 30.8" fill="none" stroke="{C2}" stroke-width="1.9" stroke-linecap="round"/>
	  <circle cx="24" cy="20.6" r="1.3" fill="{C2}"/>
	  <circle cx="24" cy="27.4" r="1.3" fill="{C1}"/>
	</svg>""",

	"seed_hongmeng": """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
	  <circle cx="24" cy="24" r="18.2" fill="none" stroke="{C2}" stroke-width="1.5" stroke-opacity="0.62"/>
	  <path d="M 10 24 Q 13 18 16.5 19.5 M 38 24 Q 35 18 31.5 19.5 M 11.5 30 Q 14.5 27 17 28.5 M 36.5 30 Q 33.5 27 31 28.5" fill="none" stroke="{C2}" stroke-width="1.7" stroke-linecap="round"/>
	  <path d="M 24 10 C 30.5 15.5 32.5 23.5 30.5 30.5 C 29 35.5 26.8 38 24 38 C 21.2 38 19 35.5 17.5 30.5 C 15.5 23.5 17.5 15.5 24 10 Z" fill="{C2}" fill-opacity="0.28" stroke="{C1}" stroke-width="2.2" stroke-linejoin="round"/>
	  <path d="M 24 17.5 L 25.4 22.6 L 30.5 24 L 25.4 25.4 L 24 30.5 L 22.6 25.4 L 17.5 24 L 22.6 22.6 Z" fill="{C2}"/>
	  <circle cx="24" cy="6.2" r="1.6" fill="{C2}"/>
	</svg>""",

	# ==================== 道藏功法 21 枚（一对一独立精绘） ====================
	"tech_changchun": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><rect x='11' y='9' width='26' height='30' rx='3' fill='{C2}' fill-opacity='0.14' stroke='{C1}' stroke-width='2.1'/><line x1='8' y1='9' x2='40' y2='9' stroke='{C1}' stroke-width='2.4' stroke-linecap='round'/><line x1='8' y1='39' x2='40' y2='39' stroke='{C1}' stroke-width='2.4' stroke-linecap='round'/><line x1='18' y1='9' x2='18' y2='39' stroke='{C1}' stroke-width='1.2' stroke-opacity='0.35'/><line x1='30' y1='9' x2='30' y2='39' stroke='{C1}' stroke-width='1.2' stroke-opacity='0.35'/><path d='M16 34 C18 26, 26 24, 32 15' fill='none' stroke='{C1}' stroke-width='2.1' stroke-linecap='round'/><path d='M21 26 C15 24, 15 18, 21 19 C22 22, 22 24, 21 26 Z' fill='{C2}' fill-opacity='0.32' stroke='{C1}' stroke-width='1.6' stroke-linejoin='round'/><path d='M27 21 C33 20, 34 25, 28 27 C26 25, 26 23, 27 21 Z' fill='{C2}' fill-opacity='0.32' stroke='{C1}' stroke-width='1.6' stroke-linejoin='round'/><path d='M32 15 C31 11, 35 11, 35 15 C34 16, 33 16, 32 15 Z' fill='{C2}' stroke='{C1}' stroke-width='1.4' stroke-linejoin='round'/><circle cx='15' cy='14' r='1.5' fill='{C2}'/></svg>""",

	"tech_lihuo": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><rect x='9' y='13' width='30' height='22' rx='2' fill='{C2}' fill-opacity='0.14' stroke='{C1}' stroke-width='2.1'/><rect x='5' y='10' width='4' height='28' rx='1.8' fill='none' stroke='{C1}' stroke-width='2'/><rect x='39' y='10' width='4' height='28' rx='1.8' fill='none' stroke='{C1}' stroke-width='2'/><path d='M24 16 C28 20, 30 24, 29 28 C28 31, 26 32, 24 32 C22 32, 20 31, 19 28 C18 24, 20 20, 24 16 Z' fill='{C2}' fill-opacity='0.3' stroke='{C1}' stroke-width='1.9' stroke-linejoin='round'/><path d='M24 22 C26 24.5, 26.5 27.5, 24 30 C21.5 27.5, 22 24.5, 24 22 Z' fill='{C2}'/><line x1='12.5' y1='20' x2='16.5' y2='20' stroke='{C1}' stroke-width='1.5' stroke-linecap='round'/><line x1='12.5' y1='24' x2='14' y2='24' stroke='{C1}' stroke-width='1.5' stroke-linecap='round'/><line x1='15' y1='24' x2='16.5' y2='24' stroke='{C1}' stroke-width='1.5' stroke-linecap='round'/><line x1='12.5' y1='28' x2='16.5' y2='28' stroke='{C1}' stroke-width='1.5' stroke-linecap='round'/><line x1='31.5' y1='20' x2='35.5' y2='20' stroke='{C1}' stroke-width='1.5' stroke-linecap='round'/><line x1='31.5' y1='24' x2='33' y2='24' stroke='{C1}' stroke-width='1.5' stroke-linecap='round'/><line x1='34' y1='24' x2='35.5' y2='24' stroke='{C1}' stroke-width='1.5' stroke-linecap='round'/><line x1='31.5' y1='28' x2='35.5' y2='28' stroke='{C1}' stroke-width='1.5' stroke-linecap='round'/></svg>""",

	"tech_baicao": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><rect x='14' y='8' width='20' height='33' rx='4' fill='{C2}' fill-opacity='0.16' stroke='{C1}' stroke-width='2.1'/><circle cx='24' cy='12.5' r='1.7' fill='none' stroke='{C1}' stroke-width='1.6'/><path d='M24 10.8 C24 6, 30 5, 34 8' fill='none' stroke='{C2}' stroke-width='1.7' stroke-linecap='round'/><path d='M24 35 L24 24' stroke='{C1}' stroke-width='2' stroke-linecap='round'/><path d='M18 24 C18 19.5, 22 18.5, 24 20.5 C26 18.5, 30 19.5, 30 24 C30 26.2, 27 26.8, 24 25.5 C21 26.8, 18 26.2, 18 24 Z' fill='{C2}' fill-opacity='0.34' stroke='{C1}' stroke-width='1.8' stroke-linejoin='round'/><path d='M24 31 C20.5 30, 19.5 28, 20.5 27.5' fill='none' stroke='{C1}' stroke-width='1.5' stroke-linecap='round'/><path d='M24 31 C27.5 30, 28.5 28, 27.5 27.5' fill='none' stroke='{C1}' stroke-width='1.5' stroke-linecap='round'/><circle cx='9.5' cy='18' r='1.6' fill='{C2}'/><circle cx='38.5' cy='28' r='1.8' fill='{C2}'/></svg>""",

	"tech_gengjin": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><polygon points='24,8 37,22 24,36 11,22' fill='{C2}' fill-opacity='0.2' stroke='{C1}' stroke-width='1.6' stroke-linejoin='round'/><polygon points='24,6 27.2,13 26.5,33 21.5,33 20.8,13' fill='{C2}' fill-opacity='0.28' stroke='{C1}' stroke-width='2' stroke-linejoin='round'/><line x1='24' y1='11' x2='24' y2='30' stroke='{C1}' stroke-width='1.4' stroke-linecap='round'/><path d='M17 32.5 Q24 35.5 31 32.5' fill='none' stroke='{C1}' stroke-width='2.3' stroke-linecap='round'/><line x1='24' y1='34' x2='24' y2='41.5' stroke='{C1}' stroke-width='2.4' stroke-linecap='round'/><circle cx='24' cy='42.2' r='1.8' fill='{C2}' stroke='{C1}' stroke-width='1.3'/><path d='M9 12 L11 10 L13 12 L11 14 Z' fill='{C2}'/><path d='M35 30 L37 28 L39 30 L37 32 Z' fill='{C2}'/></svg>""",

	"tech_jiuxiao": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><path d='M7 35 C14 34, 21 29, 28 21 C32 16, 36 13, 41 12' fill='none' stroke='{C1}' stroke-width='2.2' stroke-linecap='round'/><path d='M11 39 C19 37, 27 32, 35 23' fill='none' stroke='{C1}' stroke-width='1.7' stroke-linecap='round' stroke-opacity='0.75'/><path d='M9 28 C12 24, 17 24, 18 26.5 C21 25, 24 27, 23 29.5 C19 32, 13 31, 9 28 Z' fill='{C2}' fill-opacity='0.28' stroke='{C1}' stroke-width='1.7' stroke-linejoin='round'/><polyline points='24,7 19,17 25,17 20,27' fill='none' stroke='{C2}' stroke-width='2.3' stroke-linecap='round' stroke-linejoin='round'/><polyline points='37,16 32,24 37,24 32,33' fill='none' stroke='{C1}' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/><circle cx='39' cy='11' r='1.8' fill='{C2}'/></svg>""",

	"tech_taichu": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><polygon points='21,11 23,19 15,21 21,23' fill='{C2}' fill-opacity='0.28'/><polygon points='27,37 25,29 33,27 27,25' fill='{C2}' fill-opacity='0.28'/><path d='M21 10 L23 19 L14 21 L21 23 L17 26' fill='none' stroke='{C1}' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'/><path d='M27 38 L25 29 L34 27 L27 25 L31 22' fill='none' stroke='{C1}' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'/><path d='M7 38 C16 33, 29 22, 41 8 C35 20, 24 31, 10 40 Z' fill='{C2}' fill-opacity='0.34' stroke='{C1}' stroke-width='2' stroke-linejoin='round'/><circle cx='13' cy='13' r='1.6' fill='{C2}'/><circle cx='36' cy='35' r='1.7' fill='{C2}'/><circle cx='38' cy='19' r='1.3' fill='{C1}'/></svg>""",

	"tech_xuangui": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><polygon points='24,6 39,14.5 39,33.5 24,42 9,33.5 9,14.5' fill='{C2}' fill-opacity='0.16' stroke='{C1}' stroke-width='2.2' stroke-linejoin='round'/><polygon points='24,13 33,18.2 33,29.8 24,35 15,29.8 15,18.2' fill='none' stroke='{C1}' stroke-width='1.7' stroke-linejoin='round'/><line x1='24' y1='6' x2='24' y2='13' stroke='{C1}' stroke-width='1.6'/><line x1='39' y1='14.5' x2='33' y2='18.2' stroke='{C1}' stroke-width='1.6'/><line x1='39' y1='33.5' x2='33' y2='29.8' stroke='{C1}' stroke-width='1.6'/><line x1='24' y1='42' x2='24' y2='35' stroke='{C1}' stroke-width='1.6'/><line x1='9' y1='33.5' x2='15' y2='29.8' stroke='{C1}' stroke-width='1.6'/><line x1='9' y1='14.5' x2='15' y2='18.2' stroke='{C1}' stroke-width='1.6'/><circle cx='24' cy='24' r='4.5' fill='{C2}' fill-opacity='0.4' stroke='{C1}' stroke-width='1.9'/><circle cx='24' cy='24' r='1.6' fill='{C1}'/></svg>""",

	"tech_taixu_bijie": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><circle cx='24' cy='24' r='18' fill='{C2}' fill-opacity='0.12' stroke='{C1}' stroke-width='2'/><circle cx='24' cy='24' r='13.5' fill='none' stroke='{C1}' stroke-width='1.3' stroke-opacity='0.6'/><line x1='24' y1='4' x2='24' y2='8.5' stroke='{C1}' stroke-width='2' stroke-linecap='round'/><line x1='24' y1='39.5' x2='24' y2='44' stroke='{C1}' stroke-width='2' stroke-linecap='round'/><line x1='4' y1='24' x2='8.5' y2='24' stroke='{C1}' stroke-width='2' stroke-linecap='round'/><line x1='39.5' y1='24' x2='44' y2='24' stroke='{C1}' stroke-width='2' stroke-linecap='round'/><line x1='10' y1='10' x2='13' y2='13' stroke='{C2}' stroke-width='1.9' stroke-linecap='round'/><line x1='38' y1='10' x2='35' y2='13' stroke='{C2}' stroke-width='1.9' stroke-linecap='round'/><line x1='10' y1='38' x2='13' y2='35' stroke='{C2}' stroke-width='1.9' stroke-linecap='round'/><line x1='38' y1='38' x2='35' y2='35' stroke='{C2}' stroke-width='1.9' stroke-linecap='round'/><circle cx='24' cy='18.5' r='3' fill='{C2}' fill-opacity='0.35' stroke='{C1}' stroke-width='1.7'/><path d='M17 30 C18 24.5, 21 23, 24 23 C27 23, 30 24.5, 31 30 Z' fill='{C2}' fill-opacity='0.3' stroke='{C1}' stroke-width='1.8' stroke-linejoin='round'/><path d='M15 31.5 Q24 35.5 33 31.5' fill='none' stroke='{C1}' stroke-width='1.8' stroke-linecap='round'/></svg>""",

	"tech_zhoutian_tuna": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><path d='M11 22 A13.5 13.5 0 0 1 35 15' fill='none' stroke='{C1}' stroke-width='2.2' stroke-linecap='round'/><polyline points='30.5,14.5 35.5,15.5 34,10.5' fill='none' stroke='{C1}' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/><path d='M37 26 A13.5 13.5 0 0 1 13 33' fill='none' stroke='{C1}' stroke-width='2.2' stroke-linecap='round'/><polyline points='17.5,33.5 12.5,32.5 14,37.5' fill='none' stroke='{C1}' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/><circle cx='24' cy='24' r='7.5' fill='{C2}' fill-opacity='0.22' stroke='{C1}' stroke-width='1.8'/><path d='M24 16.5 A3.75 3.75 0 0 1 24 24 A3.75 3.75 0 0 0 24 31.5' fill='none' stroke='{C1}' stroke-width='1.7'/><circle cx='24' cy='20.2' r='1.4' fill='{C1}'/><circle cx='24' cy='27.8' r='1.4' fill='{C2}'/><circle cx='24' cy='9' r='2.2' fill='{C2}' stroke='{C1}' stroke-width='1.2'/><circle cx='24' cy='39' r='2.2' fill='{C2}' stroke='{C1}' stroke-width='1.2'/></svg>""",

	"tech_youming": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><line x1='10' y1='9' x2='38' y2='9' stroke='{C1}' stroke-width='2.4' stroke-linecap='round'/><circle cx='9.5' cy='9' r='2' fill='{C2}' stroke='{C1}' stroke-width='1.3'/><circle cx='38.5' cy='9' r='2' fill='{C2}' stroke='{C1}' stroke-width='1.3'/><path d='M14 9 L34 9 L34 32 L24 41 L14 32 Z' fill='{C2}' fill-opacity='0.18' stroke='{C1}' stroke-width='2.1' stroke-linejoin='round'/><path d='M18 16.5 L21.5 18.5 L18 19.5 Z' fill='{C2}' stroke='{C1}' stroke-width='1.2' stroke-linejoin='round'/><path d='M30 16.5 L26.5 18.5 L30 19.5 Z' fill='{C2}' stroke='{C1}' stroke-width='1.2' stroke-linejoin='round'/><path d='M24 23 C28 23, 29.5 27, 26.5 29.5 C24 31.5, 20 30, 20 27 C20 24.8, 22 23.8, 24 24.8 C25.5 25.5, 25.5 27.5, 24 28' fill='none' stroke='{C1}' stroke-width='1.8' stroke-linecap='round'/><path d='M18 35 L18 39' stroke='{C2}' stroke-width='1.6' stroke-linecap='round'/><path d='M30 35 L30 39' stroke='{C2}' stroke-width='1.6' stroke-linecap='round'/></svg>""",

	"tech_jiuyou_bumie": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><line x1='11' y1='11' x2='37' y2='37' stroke='{C1}' stroke-width='2.2' stroke-linecap='round'/><line x1='37' y1='11' x2='11' y2='37' stroke='{C1}' stroke-width='2.2' stroke-linecap='round'/><path d='M8 14 C8 9, 13 8, 15 10' fill='none' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><path d='M40 14 C40 9, 35 8, 33 10' fill='none' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><path d='M8 34 C8 39, 13 40, 15 38' fill='none' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><path d='M40 34 C40 39, 35 40, 33 38' fill='none' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><polygon points='24,12 34,20 31,34 24,38 17,34 14,20' fill='{C2}' fill-opacity='0.28' stroke='{C1}' stroke-width='2.1' stroke-linejoin='round'/><polygon points='24,18 28.5,24 24,30 19.5,24' fill='{C2}' stroke='{C1}' stroke-width='1.5' stroke-linejoin='round'/><line x1='13' y1='41' x2='35' y2='41' stroke='{C1}' stroke-width='2.3' stroke-linecap='round'/></svg>""",

	"tech_longxue": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><path d='M35 28 A13 13 0 1 1 28 11.5' fill='none' stroke='{C1}' stroke-width='2.4' stroke-linecap='round'/><path d='M27 11.5 C31 9.5, 36 11, 38 15 C35 16.5, 32 16, 30 14.5' fill='{C2}' fill-opacity='0.3' stroke='{C1}' stroke-width='1.9' stroke-linejoin='round'/><path d='M29 10 L26 6 M32 10 L35 6.5' fill='none' stroke='{C1}' stroke-width='1.8' stroke-linecap='round'/><path d='M12 20 L8 18 M11 26 L7 26 M14 33 L10 36' fill='none' stroke='{C2}' stroke-width='1.6' stroke-linecap='round'/><circle cx='24' cy='25' r='6' fill='{C2}' fill-opacity='0.38' stroke='{C1}' stroke-width='2'/><path d='M24 21.5 C26 23.5, 26 26.5, 24 28.5 C22 26.5, 22 23.5, 24 21.5 Z' fill='{C2}'/><path d='M31 35 C34 34, 37 31, 38 27' fill='none' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/></svg>""",

	"tech_xinghe_jian": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><line x1='24' y1='6.5' x2='24' y2='13' stroke='{C1}' stroke-width='2.4' stroke-linecap='round'/><path d='M17.5 14 Q24 11 30.5 14' fill='none' stroke='{C1}' stroke-width='2.2' stroke-linecap='round'/><polygon points='21.5,14 26.5,14 26,35 24,42 22,35' fill='{C2}' fill-opacity='0.22' stroke='{C1}' stroke-width='2' stroke-linejoin='round'/><path d='M10 19 C13 13, 35 15, 38 22 C40 28, 12 26, 10 33 C9 37, 18 39, 34 36' fill='none' stroke='{C2}' stroke-width='2.1' stroke-linecap='round'/><path d='M11 12 L12.5 9.5 L14 12 L12.5 14.5 Z' fill='{C2}'/><path d='M36 12 L37.5 9.5 L39 12 L37.5 14.5 Z' fill='{C2}'/><path d='M35 33 L36.5 30.5 L38 33 L36.5 35.5 Z' fill='{C1}'/><circle cx='11' cy='27' r='1.4' fill='{C1}'/></svg>""",

	"tech_xingchen_lianshen": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><polyline points='8,17 14,13 21,14 27,12 31,17 39,16 37,10' fill='none' stroke='{C2}' stroke-width='1.5' stroke-linecap='round' stroke-linejoin='round'/><circle cx='8' cy='17' r='1.6' fill='{C2}'/><circle cx='14' cy='13' r='1.6' fill='{C2}'/><circle cx='21' cy='14' r='1.6' fill='{C2}'/><circle cx='27' cy='12' r='1.7' fill='{C2}'/><circle cx='31' cy='17' r='1.6' fill='{C2}'/><circle cx='39' cy='16' r='1.6' fill='{C2}'/><circle cx='37' cy='10' r='1.8' fill='{C2}'/><path d='M8 29 C14 21.5, 34 21.5, 40 29 C34 36.5, 14 36.5, 8 29 Z' fill='{C2}' fill-opacity='0.2' stroke='{C1}' stroke-width='2.1' stroke-linejoin='round'/><circle cx='24' cy='29' r='5.5' fill='none' stroke='{C1}' stroke-width='1.8'/><circle cx='24' cy='29' r='2.2' fill='{C2}' stroke='{C1}' stroke-width='1.2'/><line x1='24' y1='38' x2='24' y2='42' stroke='{C1}' stroke-width='1.7' stroke-linecap='round'/><line x1='17' y1='37' x2='15' y2='40' stroke='{C2}' stroke-width='1.5' stroke-linecap='round'/><line x1='31' y1='37' x2='33' y2='40' stroke='{C2}' stroke-width='1.5' stroke-linecap='round'/></svg>""",

	"tech_yinhe_guangai": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><path d='M13 8 L19 12 L17 15 C21 17, 22 22, 18 25 C14 28, 9 26, 8 21 C7 17, 10 14, 13 13 Z' fill='{C2}' fill-opacity='0.24' stroke='{C1}' stroke-width='2' stroke-linejoin='round'/><path d='M20 14 C27 15, 32 20, 33 27' fill='none' stroke='{C2}' stroke-width='2.1' stroke-linecap='round'/><path d='M21 18 C26 19.5, 28.5 23, 29 28' fill='none' stroke='{C1}' stroke-width='1.5' stroke-linecap='round' stroke-opacity='0.7'/><circle cx='26' cy='13.5' r='1.4' fill='{C2}'/><circle cx='34.5' cy='20' r='1.5' fill='{C2}'/><circle cx='25' cy='25' r='1.3' fill='{C2}'/><path d='M31 39 C26 37, 23 33, 25 30 C28 30, 30 33, 31 37 C32 33, 34 30, 37 30 C39 33, 36 37, 31 39 Z' fill='{C2}' fill-opacity='0.32' stroke='{C1}' stroke-width='1.8' stroke-linejoin='round'/><path d='M31 37 C29 32, 29.5 28, 31 26.5 C32.5 28, 33 32, 31 37 Z' fill='{C2}' fill-opacity='0.36' stroke='{C1}' stroke-width='1.8' stroke-linejoin='round'/><path d='M21 40 Q31 42 41 40' fill='none' stroke='{C1}' stroke-width='1.8' stroke-linecap='round'/></svg>""",

	"tech_hundun_kaitian": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><path d='M18 11 A14 14 0 0 0 18 37' fill='none' stroke='{C1}' stroke-width='2' stroke-linecap='round'/><path d='M30 11 A14 14 0 0 1 30 37' fill='none' stroke='{C1}' stroke-width='2' stroke-linecap='round'/><path d='M24 6 L24 42' stroke='{C1}' stroke-width='2.4' stroke-linecap='round'/><path d='M24 12 C31 11, 36 14, 38 20 C36 26, 31 29, 24 27 Z' fill='{C2}' fill-opacity='0.32' stroke='{C1}' stroke-width='2.1' stroke-linejoin='round'/><path d='M24 14 C19 14, 15 16, 14 20 C15 24, 19 26, 24 25 Z' fill='{C2}' fill-opacity='0.22' stroke='{C1}' stroke-width='1.9' stroke-linejoin='round'/><line x1='16' y1='8' x2='12' y2='5.5' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><line x1='32' y1='8' x2='36' y2='5.5' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><line x1='15' y1='39' x2='11' y2='41.5' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><line x1='33' y1='39' x2='37' y2='41.5' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/></svg>""",

	"tech_hunyuan_yiqi": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><ellipse cx='24' cy='28' rx='16' ry='7.5' fill='none' stroke='{C1}' stroke-width='1.8'/><ellipse cx='24' cy='28' rx='15' ry='7' transform='rotate(55 24 28)' fill='none' stroke='{C1}' stroke-width='1.6' stroke-opacity='0.8'/><ellipse cx='24' cy='28' rx='15' ry='7' transform='rotate(-55 24 28)' fill='none' stroke='{C2}' stroke-width='1.7'/><circle cx='24' cy='28' r='4.5' fill='{C2}' fill-opacity='0.4' stroke='{C1}' stroke-width='1.9'/><path d='M24 13 C21.5 10, 22 6.5, 24 5.5 C26 6.5, 26.5 10, 24 13 Z' fill='{C2}' fill-opacity='0.38' stroke='{C1}' stroke-width='1.6' stroke-linejoin='round'/><path d='M15 15.5 C12 13.5, 11.5 10.5, 13 9 C15 9.5, 16.5 12, 15 15.5 Z' fill='{C2}' fill-opacity='0.3' stroke='{C1}' stroke-width='1.5' stroke-linejoin='round'/><path d='M33 15.5 C36 13.5, 36.5 10.5, 35 9 C33 9.5, 31.5 12, 33 15.5 Z' fill='{C2}' fill-opacity='0.3' stroke='{C1}' stroke-width='1.5' stroke-linejoin='round'/></svg>""",

	"tech_zaohua_dan": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><path d='M16 20 L32 20 C34 26, 32 32, 24 32 C16 32, 14 26, 16 20 Z' fill='{C2}' fill-opacity='0.24' stroke='{C1}' stroke-width='2' stroke-linejoin='round'/><path d='M15 21 C11 20, 11 25, 14.5 26' fill='none' stroke='{C1}' stroke-width='1.8' stroke-linecap='round'/><path d='M33 21 C37 20, 37 25, 33.5 26' fill='none' stroke='{C1}' stroke-width='1.8' stroke-linecap='round'/><line x1='18' y1='31.5' x2='16' y2='36' stroke='{C1}' stroke-width='2' stroke-linecap='round'/><line x1='24' y1='32' x2='24' y2='36.5' stroke='{C1}' stroke-width='2' stroke-linecap='round'/><line x1='30' y1='31.5' x2='32' y2='36' stroke='{C1}' stroke-width='2' stroke-linecap='round'/><path d='M7 36 C13 39.5, 35 39.5, 41 36 L39 41 C33 43, 15 43, 9 41 Z' fill='{C2}' fill-opacity='0.16' stroke='{C1}' stroke-width='1.8' stroke-linejoin='round'/><circle cx='24' cy='11.5' r='3.6' fill='{C2}' fill-opacity='0.45' stroke='{C1}' stroke-width='1.7'/><path d='M13 14 C15 11, 18 11, 19.5 13' fill='none' stroke='{C2}' stroke-width='1.6' stroke-linecap='round'/><path d='M35 14 C33 11, 30 11, 28.5 13' fill='none' stroke='{C2}' stroke-width='1.6' stroke-linecap='round'/><line x1='24' y1='5' x2='24' y2='6.8' stroke='{C2}' stroke-width='1.6' stroke-linecap='round'/></svg>""",

	"tech_hongmeng_zhuxian": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><circle cx='24' cy='24' r='18' fill='none' stroke='{C2}' stroke-width='1.4' stroke-opacity='0.65'/><polygon points='24,16 32,24 24,32 16,24' fill='{C2}' fill-opacity='0.34' stroke='{C1}' stroke-width='1.9' stroke-linejoin='round'/><circle cx='24' cy='24' r='2.2' fill='{C1}'/><line x1='8' y1='8' x2='18.5' y2='18.5' stroke='{C1}' stroke-width='2.2' stroke-linecap='round'/><line x1='9' y1='14' x2='14' y2='9' stroke='{C2}' stroke-width='2' stroke-linecap='round'/><line x1='40' y1='8' x2='29.5' y2='18.5' stroke='{C1}' stroke-width='2.2' stroke-linecap='round'/><line x1='34' y1='9' x2='39' y2='14' stroke='{C2}' stroke-width='2' stroke-linecap='round'/><line x1='8' y1='40' x2='18.5' y2='29.5' stroke='{C1}' stroke-width='2.2' stroke-linecap='round'/><line x1='9' y1='34' x2='14' y2='39' stroke='{C2}' stroke-width='2' stroke-linecap='round'/><line x1='40' y1='40' x2='29.5' y2='29.5' stroke='{C1}' stroke-width='2.2' stroke-linecap='round'/><line x1='34' y1='39' x2='39' y2='34' stroke='{C2}' stroke-width='2' stroke-linecap='round'/></svg>""",

	"tech_taixu_zhengdao": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><path d='M6 27 C12 24.5, 19 25.5, 24 29.5 C29 25.5, 36 24.5, 42 27 L40 39 C34 36.5, 28 37.5, 24 41 C20 37.5, 14 36.5, 8 39 Z' fill='{C2}' fill-opacity='0.18' stroke='{C1}' stroke-width='2' stroke-linejoin='round'/><line x1='24' y1='29.5' x2='24' y2='41' stroke='{C1}' stroke-width='1.8'/><path d='M24 26 C21 21, 21.5 16, 24 14 C26.5 16, 27 21, 24 26 Z' fill='{C2}' fill-opacity='0.4' stroke='{C1}' stroke-width='1.7' stroke-linejoin='round'/><path d='M24 26 C18 24, 15 20, 16.5 17.5 C19.5 18, 22 21, 24 26 Z' fill='{C2}' fill-opacity='0.28' stroke='{C1}' stroke-width='1.6' stroke-linejoin='round'/><path d='M24 26 C30 24, 33 20, 31.5 17.5 C28.5 18, 26 21, 24 26 Z' fill='{C2}' fill-opacity='0.28' stroke='{C1}' stroke-width='1.6' stroke-linejoin='round'/><path d='M15 14 A10 10 0 0 1 33 14' fill='none' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><line x1='24' y1='5' x2='24' y2='8.5' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><line x1='14' y1='8.5' x2='16.5' y2='11' stroke='{C2}' stroke-width='1.6' stroke-linecap='round'/><line x1='34' y1='8.5' x2='31.5' y2='11' stroke='{C2}' stroke-width='1.6' stroke-linecap='round'/></svg>""",

	"tech_zhoutian_xingdou": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><circle cx='24' cy='24' r='19' fill='{C2}' fill-opacity='0.12' stroke='{C1}' stroke-width='2'/><circle cx='24' cy='24' r='13.5' fill='none' stroke='{C1}' stroke-width='1.3' stroke-opacity='0.65'/><rect x='14.5' y='14.5' width='19' height='19' fill='none' stroke='{C1}' stroke-width='1.5'/><polygon points='24,10.5 37.5,24 24,37.5 10.5,24' fill='none' stroke='{C2}' stroke-width='1.6' stroke-linejoin='round'/><circle cx='24' cy='5' r='1.8' fill='{C2}' stroke='{C1}' stroke-width='1'/><circle cx='24' cy='43' r='1.8' fill='{C2}' stroke='{C1}' stroke-width='1'/><circle cx='5' cy='24' r='1.8' fill='{C2}' stroke='{C1}' stroke-width='1'/><circle cx='43' cy='24' r='1.8' fill='{C2}' stroke='{C1}' stroke-width='1'/><circle cx='10.6' cy='10.6' r='1.5' fill='{C1}'/><circle cx='37.4' cy='10.6' r='1.5' fill='{C1}'/><circle cx='10.6' cy='37.4' r='1.5' fill='{C1}'/><circle cx='37.4' cy='37.4' r='1.5' fill='{C1}'/><circle cx='22.5' cy='24' r='4.5' fill='{C2}' fill-opacity='0.45' stroke='{C1}' stroke-width='1.7'/><path d='M26.5 19.5 A5 5 0 0 1 26.5 28.5 A3.6 3.6 0 0 0 26.5 19.5 Z' fill='{C1}'/>	</svg>""",

# ==================== 吐纳功课 8 枚（炼气→大乘 进阶） ====================
"act_meditate_qi": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><ellipse cx='24' cy='37.5' rx='13.5' ry='3.8' fill='{C2}' fill-opacity='0.22' stroke='{C1}' stroke-width='1.9'/><circle cx='24' cy='17.5' r='3.6' fill='{C2}' fill-opacity='0.24' stroke='{C1}' stroke-width='2'/><path d='M15 35 C15.5 28, 19 24.5, 24 24.5 C29 24.5, 32.5 28, 33 35 Z' fill='{C2}' fill-opacity='0.18' stroke='{C1}' stroke-width='2' stroke-linejoin='round'/><circle cx='24' cy='30.5' r='1.8' fill='{C2}'/><path d='M11 26 C9.5 21, 12 16.5, 15 14' fill='none' stroke='{C2}' stroke-width='1.7' stroke-linecap='round'/><path d='M37 26 C38.5 21, 36 16.5, 33 14' fill='none' stroke='{C2}' stroke-width='1.7' stroke-linecap='round'/><path d='M24 10.5 L24 7.5' stroke='{C2}' stroke-width='1.6' stroke-linecap='round'/></svg>""",

"act_meditate_foundation": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><polygon points='10,39 38,39 34.5,33 13.5,33' fill='{C2}' fill-opacity='0.24' stroke='{C1}' stroke-width='2' stroke-linejoin='round'/><path d='M14 33 C11.5 29.5, 13.5 26, 18 28.5 C20 25, 28 25, 30 28.5 C34.5 26, 36.5 29.5, 34 33' fill='{C2}' fill-opacity='0.2' stroke='{C1}' stroke-width='1.8' stroke-linejoin='round'/><polygon points='24,14 29,21 24,28 19,21' fill='{C2}' fill-opacity='0.36' stroke='{C1}' stroke-width='2' stroke-linejoin='round'/><circle cx='24' cy='21' r='1.8' fill='{C1}'/><path d='M9 12 C11.5 18, 15 21, 18 22.5' fill='none' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><path d='M39 12 C36.5 18, 33 21, 30 22.5' fill='none' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><line x1='24' y1='6.5' x2='24' y2='10.5' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/></svg>""",

"act_meditate_core": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><path d='M10 21 A14.5 14.5 0 0 1 36 15' fill='none' stroke='{C1}' stroke-width='1.9' stroke-linecap='round'/><path d='M38 27 A14.5 14.5 0 0 1 12 33' fill='none' stroke='{C1}' stroke-width='1.9' stroke-linecap='round'/><circle cx='24' cy='24' r='8.5' fill='{C2}' fill-opacity='0.38' stroke='{C1}' stroke-width='2.1'/><path d='M20.5 20.5 A5 5 0 0 1 26.5 19' fill='none' stroke='{C1}' stroke-width='1.6' stroke-linecap='round'/><circle cx='24' cy='24' r='2.4' fill='{C2}' stroke='{C1}' stroke-width='1.2'/><line x1='24' y1='6' x2='24' y2='11' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><line x1='24' y1='37' x2='24' y2='42' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><line x1='6' y1='24' x2='11' y2='24' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><line x1='37' y1='24' x2='42' y2='24' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><circle cx='36' cy='15' r='1.8' fill='{C2}'/><circle cx='12' cy='33' r='1.8' fill='{C2}'/></svg>""",

"act_meditate_nascent": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><circle cx='24' cy='16.5' r='7.5' fill='{C2}' fill-opacity='0.22' stroke='{C2}' stroke-width='1.5'/><circle cx='24' cy='16.5' r='3.6' fill='{C2}' fill-opacity='0.34' stroke='{C1}' stroke-width='1.9'/><path d='M17.5 31.5 C18 25, 20.5 22.5, 24 22.5 C27.5 22.5, 30 25, 30.5 31.5 Z' fill='{C2}' fill-opacity='0.3' stroke='{C1}' stroke-width='1.9' stroke-linejoin='round'/><path d='M13 25 C9 20, 10 13, 15 10.5' fill='none' stroke='{C1}' stroke-width='1.7' stroke-linecap='round'/><path d='M35 25 C39 20, 38 13, 33 10.5' fill='none' stroke='{C1}' stroke-width='1.7' stroke-linecap='round'/><path d='M12 34.5 Q24 41.5 36 34.5' fill='none' stroke='{C1}' stroke-width='2' stroke-linecap='round'/><path d='M16 36 C19 32.5, 22 33.5, 24 36.5 C26 33.5, 29 32.5, 32 36' fill='{C2}' fill-opacity='0.28' stroke='{C1}' stroke-width='1.6' stroke-linejoin='round'/><circle cx='24' cy='6.5' r='1.6' fill='{C2}'/></svg>""",

"act_meditate_spirit": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><path d='M12 37.5 Q24 42.5 36 37.5' fill='none' stroke='{C1}' stroke-width='2' stroke-linecap='round'/><path d='M24 36 C18 32, 16 25, 20 18 C22 14.5, 23 11.5, 24 8.5 C25 11.5, 26 14.5, 28 18 C32 25, 30 32, 24 36 Z' fill='{C2}' fill-opacity='0.28' stroke='{C1}' stroke-width='2' stroke-linejoin='round'/><path d='M24 31 C21.5 28.5, 21.5 23.5, 24 19.5 C26.5 23.5, 26.5 28.5, 24 31 Z' fill='{C2}' fill-opacity='0.45'/><path d='M9 22 C13 22, 15.5 24, 17 26.5' fill='none' stroke='{C2}' stroke-width='1.7' stroke-linecap='round'/><path d='M39 22 C35 22, 32.5 24, 31 26.5' fill='none' stroke='{C2}' stroke-width='1.7' stroke-linecap='round'/><path d='M11 12 L15 15.5' stroke='{C1}' stroke-width='1.6' stroke-linecap='round'/><path d='M37 12 L33 15.5' stroke='{C1}' stroke-width='1.6' stroke-linecap='round'/><polygon points='24,4.5 25.6,7.5 24,10.5 22.4,7.5' fill='{C2}'/><circle cx='9' cy='22' r='1.6' fill='{C2}'/><circle cx='39' cy='22' r='1.6' fill='{C2}'/></svg>""",

"act_meditate_void": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><ellipse cx='24' cy='24' rx='17.5' ry='7.5' transform='rotate(35 24 24)' fill='none' stroke='{C1}' stroke-width='1.8'/><ellipse cx='24' cy='24' rx='17.5' ry='7.5' transform='rotate(-35 24 24)' fill='none' stroke='{C2}' stroke-width='1.8'/><path d='M24 9.5 C29 16, 29 32, 24 38.5 C19 32, 19 16, 24 9.5 Z' fill='{C2}' fill-opacity='0.24' stroke='{C1}' stroke-width='2' stroke-linejoin='round'/><circle cx='24' cy='24' r='3.5' fill='{C2}' stroke='{C1}' stroke-width='1.6'/><circle cx='24' cy='6' r='1.5' fill='{C2}'/><circle cx='24' cy='42' r='1.5' fill='{C2}'/><circle cx='7.5' cy='24' r='1.6' fill='{C1}'/><circle cx='40.5' cy='24' r='1.6' fill='{C1}'/></svg>""",

"act_meditate_unity": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><circle cx='24' cy='24' r='18.5' fill='{C2}' fill-opacity='0.12' stroke='{C1}' stroke-width='1.8'/><circle cx='24' cy='24' r='14.5' fill='none' stroke='{C2}' stroke-width='1.4' stroke-opacity='0.75'/><line x1='24' y1='5.5' x2='24' y2='9.5' stroke='{C1}' stroke-width='2' stroke-linecap='round'/><line x1='24' y1='38.5' x2='24' y2='42.5' stroke='{C1}' stroke-width='2' stroke-linecap='round'/><line x1='5.5' y1='24' x2='9.5' y2='24' stroke='{C1}' stroke-width='2' stroke-linecap='round'/><line x1='38.5' y1='24' x2='42.5' y2='24' stroke='{C1}' stroke-width='2' stroke-linecap='round'/><line x1='11' y1='11' x2='14' y2='14' stroke='{C2}' stroke-width='1.9' stroke-linecap='round'/><line x1='37' y1='11' x2='34' y2='14' stroke='{C2}' stroke-width='1.9' stroke-linecap='round'/><line x1='11' y1='37' x2='14' y2='34' stroke='{C2}' stroke-width='1.9' stroke-linecap='round'/><line x1='37' y1='37' x2='34' y2='34' stroke='{C2}' stroke-width='1.9' stroke-linecap='round'/><circle cx='24' cy='24' r='9.5' fill='{C2}' fill-opacity='0.26' stroke='{C1}' stroke-width='2'/><path d='M24 14.5 A4.75 4.75 0 0 1 24 24 A4.75 4.75 0 0 0 24 33.5' fill='none' stroke='{C1}' stroke-width='1.8'/><circle cx='24' cy='19.2' r='1.7' fill='{C1}'/><circle cx='24' cy='28.8' r='1.7' fill='{C2}' stroke='{C1}' stroke-width='1'/></svg>""",

"act_meditate_mahayana": """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 48 48'><path d='M11 37 L11 20 A13 13 0 0 1 37 20 L37 37' fill='{C2}' fill-opacity='0.14' stroke='{C1}' stroke-width='2.1' stroke-linecap='round'/><path d='M15 37 L15 20.5 A9 9 0 0 1 33 20.5 L33 37' fill='none' stroke='{C2}' stroke-width='1.4' stroke-opacity='0.8'/><path d='M6.5 39 C10.5 35.5, 16 35.5, 19.5 38.5 C22 36, 26 36, 28.5 38.5 C32 35.5, 37.5 35.5, 41.5 39' fill='none' stroke='{C1}' stroke-width='2.1' stroke-linecap='round' stroke-linejoin='round'/><circle cx='24' cy='22.5' r='5' fill='{C2}' fill-opacity='0.44' stroke='{C1}' stroke-width='1.9'/><line x1='24' y1='13.5' x2='24' y2='15.8' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><line x1='24' y1='29.2' x2='24' y2='32.5' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><line x1='17.5' y1='22.5' x2='15.5' y2='22.5' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><line x1='30.5' y1='22.5' x2='32.5' y2='22.5' stroke='{C2}' stroke-width='1.8' stroke-linecap='round'/><polygon points='24,4 26.2,7.2 24,10.2 21.8,7.2' fill='{C2}' stroke='{C1}' stroke-width='1.2' stroke-linejoin='round'/><line x1='15' y1='8.5' x2='17.5' y2='10.5' stroke='{C2}' stroke-width='1.6' stroke-linecap='round'/><line x1='33' y1='8.5' x2='30.5' y2='10.5' stroke='{C2}' stroke-width='1.6' stroke-linecap='round'/></svg>"""
}

## 物品 ID -> 图标模板键映射（含高阶装备/丹药/法器自动复用）
const ITEM_KEY_MAP: Dictionary = {
	"item_qingye": "item_qingye",
	"item_ninglu": "item_ninglu",
	"item_ziyun": "item_ziyun",
	"item_chiyan": "item_chiyan",
	"item_qingling_wood": "item_wood",
	"item_ironwood": "item_ironwood",
	"item_thunderwood": "item_thunderwood",
	"item_crude_iron": "item_ore",
	"item_mithril": "item_mithril",
	"item_redgold": "item_redgold",
	"seed_qingye": "item_seed",
	"seed_ninglu": "seed_ninglu",
	"seed_spirit_berry": "seed_spirit_berry",
	"seed_ziyun": "seed_ziyun",
	"seed_chiyan": "seed_chiyan",
	"item_spirit_berry": "item_spirit_berry",
	"item_beast_core": "item_beast_core",
	"item_demon_essence": "item_demon_essence",
	"item_qi_pill": "item_pill",
	"item_peiyuan_pill": "item_peiyuan_pill",
	"item_heal_powder": "item_heal_pill",
	"item_big_heal": "item_big_heal",
	"item_foundation_pill": "item_breakthrough_pill",
	"item_jindan_pill": "item_jindan_pill",
	"item_earth_talisman": "item_shield_talisman",
	"item_turtle_talisman": "item_turtle_talisman",
	"item_thunder_talisman": "item_thunder_talisman",
	"item_fireball_talisman": "item_fireball_talisman",
	"item_qingmu_ward": "item_qingmu_ward",
	"item_jianmu_ward": "item_jianmu_ward",
	"item_xingchen_thunder": "item_xingchen_thunder",
	"item_hundun_thunder": "item_hundun_thunder",
	"item_worldtree_ward": "item_worldtree_ward",
	"item_cuiyun_wood": "item_cuiyun_wood",
	"item_qinggang_ore": "item_qinggang_ore",
	"equip_qinggang_sword": "equip_qinggang_sword",
	"equip_cuiyun_robe": "equip_cuiyun_robe",
	"item_taiyi_heal": "item_taiyi_heal",
	"item_hundun_heal": "item_hundun_heal",
	"item_hongmeng_heal": "item_hongmeng_heal",
	"ui_fishing_rod": "ui_fishing_rod",
	"ui_tea_pot": "ui_tea_pot",
	"item_spirit_dew": "item_spirit_dew",
	"item_spirit_nectar": "item_spirit_nectar",
	"item_spirit_fish": "item_spirit_fish",
	"equip_iron_sword": "equip_sword",
	"equip_mithril_sword": "equip_mithril_sword",
	"equip_redgold_sword": "equip_redgold_sword",
	"equip_iron_robe": "equip_robe",
	"equip_mithril_armor": "equip_mithril_armor",
	"equip_redgold_robe": "equip_redgold_robe",
	"tool_herb_hoe_1": "tool_hoe_qingtong",
	"tool_herb_hoe_2": "tool_hoe_biyu",
	"tool_wood_axe_1": "tool_axe_xuantie",
	"tool_wood_axe_2": "tool_axe_hantie",
	"tool_mine_pick_1": "tool_pick_poyan",
	"tool_mine_pick_2": "tool_pick_xuanjin",
	"gear_alchemy_furnace_1": "gear_furnace_qingtong",
	"gear_alchemy_furnace_2": "gear_furnace_bagua",
	"gear_forge_hammer_1": "gear_hammer_dihuo",
	"gear_meditate_mat_1": "gear_mat_juling",
	"gear_combat_bell_1": "gear_bell_charm",
	"gear_talisman_brush_1": "gear_brush_zihao",
	"gear_auto_pill_array": "gear_array",
	"farm_plot_2": "nav_farm",
	"farm_plot_3": "farm_plot_3",
	"farm_plot_4": "farm_plot_4",
	# ---- 金丹期新物品（复用造型，五行/品质配色区分三阶质感）
	"item_hansui": "item_hansui",
	"item_xinghui": "item_xinghui",
	"item_icewood": "item_icewood",
	"item_starwood": "item_starwood",
	"item_stariron": "item_stariron",
	"item_primordial_crystal": "item_primordial_crystal",
	"item_star_core": "item_star_core",
	"item_ancient_soul": "item_ancient_soul",
	"item_gold_pill": "item_gold_pill",
	"item_heart_pill": "item_heart_pill",
	"item_nascent_pill": "item_nascent_pill",
	"item_taiji_talisman": "item_taiji_talisman",
	"item_zixiao_talisman": "item_zixiao_talisman",
	"equip_star_sword": "equip_star_sword",
	"equip_primordial_sword": "equip_primordial_sword",
	"equip_ice_armor": "equip_ice_armor",
	"equip_primordial_robe": "equip_primordial_robe",
	"seed_hansui": "seed_hansui",
	"seed_xinghui": "seed_xinghui",
	"tool_herb_hoe_3": "tool_hoe_star",
	"tool_wood_axe_3": "tool_axe_ice",
	"tool_mine_pick_3": "tool_pick_primordial",
	"gear_alchemy_furnace_3": "gear_furnace_ding",
	"gear_combat_bell_2": "gear_bell_soul",
	# ---- 元婴期新物品
	"item_jiuye": "item_jiuye",
	"item_fusang": "item_fusang",
	"item_taixu_gold": "item_taixu_gold",
	"item_thunder_essence": "item_thunder_essence",
	"item_dragon_scale": "item_dragon_scale",
	"item_yuanying_pill": "item_yuanying_pill",
	"item_revive_pill": "item_revive_pill",
	"item_ascension_pill": "item_ascension_pill",
	"item_taixu_shield": "item_taixu_shield",
	"item_taixu_thunder": "item_taixu_thunder",
	"equip_taixu_sword": "equip_taixu_sword",
	"equip_taixu_robe": "equip_taixu_robe",
	"seed_jiuye": "seed_jiuye",
	"seed_biyu": "seed_biyu",
	"seed_longxue": "seed_longxue",
	"seed_taiyi": "seed_taiyi",
	"seed_hundun": "seed_hundun",
	"seed_hongmeng": "seed_hongmeng",
	# ---- 灵田专属奇珍
	"item_crimson_fruit": "item_crimson_fruit",
	"gear_taixu_furnace": "gear_furnace_taixu",
	"gear_taixu_bell": "gear_bell_dao",
	# ---- v4 高阶内容（同系列共用造型，五行/品质决定点缀色）
	"item_biyu_shen": "item_biyu_shen",
	"item_longxue": "item_longxue",
	"item_taiyi_lian": "item_taiyi_lian",
	"item_hundun_flower": "item_hundun_flower",
	"item_hongmeng_herb": "item_hongmeng_herb",
	"item_chiyan_wutong": "item_chiyan_wutong",
	"item_jianmu": "item_jianmu",
	"item_xingchen_sang": "item_xingchen_sang",
	"item_hundun_vine": "item_hundun_vine",
	"item_worldtree": "item_worldtree",
	"item_hanyu": "item_hanyu",
	"item_jiuyou_crystal": "item_jiuyou_crystal",
	"item_xingyun_iron": "item_xingyun_iron",
	"item_hundun_stone": "item_hundun_stone",
	"item_hongmeng_gold": "item_hongmeng_gold",
	"item_huashen_pill": "item_huashen_pill",
	"item_lianxu_pill": "item_lianxu_pill",
	"item_heti_pill": "item_heti_pill",
	"item_dacheng_pill": "item_dacheng_pill",
	"item_jiuzhuan_pill": "item_jiuzhuan_pill",
	"item_trib_huashen": "item_trib_huashen",
	"item_trib_lianxu": "item_trib_lianxu",
	"item_trib_heti": "item_trib_heti",
	"item_trib_dacheng": "item_trib_dacheng",
	"item_qingxin_pill": "item_qingxin_pill",
	"item_huashen_note": "item_note",
	"item_xuanbing_talisman": "item_xuanbing_talisman",
	"item_jiuyou_ward": "item_jiuyou_ward",
	"item_xingyun_ward": "item_xingyun_ward",
	"item_hundun_ward": "item_hundun_ward",
	"item_hongmeng_thunder": "item_hongmeng_thunder",
	"equip_jiuyou_sword": "equip_jiuyou_sword",
	"equip_xinghe_sword": "equip_xinghe_sword",
	"equip_hongmeng_sword": "equip_hongmeng_sword",
	"equip_hundun_axe": "equip_hundun_axe",
	"equip_mingyuan_armor": "equip_mingyuan_armor",
	"equip_xingchen_robe": "equip_xingchen_robe",
	"equip_hunyuan_robe": "equip_hunyuan_robe",
	"equip_zaohua_robe": "equip_zaohua_robe"
}



