#!/usr/bin/env python3
"""
Script para gerar a logo PNG da Pastelaria Ponto de Amigos
Requisito: pip install pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_pastelaria_logo(size=1024, output_path="assets/images/app_icon.png"):
    """
    Cria a logo PNG da Pastelaria Ponto de Amigos
    
    Args:
        size: Tamanho da imagem (em pixels)
        output_path: Caminho onde salvar a imagem
    """
    
    # Criar imagem com fundo preto
    img = Image.new('RGB', (size, size), color='black')
    draw = ImageDraw.Draw(img)
    
    # Proporções
    pastel_size = int(size * 0.41)
    pastel_x = (size - pastel_size) // 2
    pastel_y = int(size * 0.195)
    
    # Cores
    yellow = '#FFD700'
    black = '#000000'
    
    # Desenhar quadrado amarelo principal (pastel)
    draw.rounded_rectangle(
        [pastel_x, pastel_y, pastel_x + pastel_size, pastel_y + pastel_size],
        radius=int(size * 0.02),
        fill=yellow
    )
    
    # Triângulo do topo esquerdo
    triangle_points = [
        (pastel_x, int(pastel_y - size * 0.078)),
        (int(pastel_x + size * 0.078), int(pastel_y - size * 0.156)),
        (int(pastel_x + size * 0.078), int(pastel_y - size * 0.078))
    ]
    draw.polygon(triangle_points, fill=yellow)
    
    # Barra horizontal do topo
    bar_x1 = int(pastel_x + size * 0.098)
    bar_y1 = int(pastel_y - size * 0.215)
    bar_x2 = int(bar_x1 + size * 0.293)
    bar_y2 = int(bar_y1 + size * 0.098)
    draw.rounded_rectangle(
        [bar_x1, bar_y1, bar_x2, bar_y2],
        radius=int(size * 0.01),
        fill=yellow
    )
    
    # Espessura das linhas para olhos e boca
    stroke_width = int(size * 0.0234)
    
    # Olho esquerdo (arco)
    eye_left_center = (int(pastel_x + size * 0.195), int(pastel_y + size * 0.195))
    eye_radius = int(size * 0.039)
    # Desenhar meia circunferência para o olho
    draw.arc(
        [eye_left_center[0] - eye_radius, eye_left_center[1] - eye_radius,
         eye_left_center[0] + eye_radius, eye_left_center[1] + eye_radius],
        0, 180,
        fill=black,
        width=stroke_width
    )
    
    # Olho direito (arco)
    eye_right_center = (int(pastel_x + pastel_size - size * 0.117), int(pastel_y + size * 0.195))
    draw.arc(
        [eye_right_center[0] - eye_radius, eye_right_center[1] - eye_radius,
         eye_right_center[0] + eye_radius, eye_right_center[1] + eye_radius],
        0, 180,
        fill=black,
        width=stroke_width
    )
    
    # Boca (arco)
    mouth_y = int(pastel_y + size * 0.293)
    mouth_left = int(pastel_x + size * 0.117)
    mouth_right = int(pastel_x + pastel_size - size * 0.117)
    mouth_bottom = int(mouth_y + size * 0.059)
    draw.arc(
        [mouth_left, mouth_y, mouth_right, mouth_bottom],
        0, 180,
        fill=black,
        width=stroke_width
    )
    
    # Criar diretório se não existir
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Salvar imagem
    img.save(output_path)
    print(f"✓ Logo gerada com sucesso: {output_path}")
    print(f"  Tamanho: {size}x{size} pixels")

if __name__ == "__main__":
    # Gerar logo em tamanho grande (para App Store e uso geral)
    create_pastelaria_logo(1024, "assets/images/app_icon.png")
    
    # Gerar ícones em diferentes tamanhos para Android
    sizes = {
        192: "assets/images/icon_192.png",  # xxxhdpi
        144: "assets/images/icon_144.png",  # xxhdpi
        96: "assets/images/icon_96.png",    # xhdpi
        72: "assets/images/icon_72.png",    # hdpi
        48: "assets/images/icon_48.png",    # mdpi
    }
    
    for size, path in sizes.items():
        create_pastelaria_logo(size, path)
    
    print("\n✓ Todas as logos foram geradas com sucesso!")
    print("\nProximos passos:")
    print("1. Copie os arquivos gerados para os diretórios do Android:")
    print("   - icon_192.png -> android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png")
    print("   - icon_144.png -> android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png")
    print("   - icon_96.png -> android/app/src/main/res/mipmap-xhdpi/ic_launcher.png")
    print("   - icon_72.png -> android/app/src/main/res/mipmap-hdpi/ic_launcher.png")
    print("   - icon_48.png -> android/app/src/main/res/mipmap-mdpi/ic_launcher.png")
    print("\n2. Execute: flutter pub run flutter_launcher_icons")
